namespace :contention do
  require 'rake_utils'

  desc "Import contention data XML and assets."
  task :import => :environment do
    require 'contention/importer'
    include Contention::Importer

    timestamp = Time.now.strftime("%Y%m%d%H%M%S")     # will be used eg. in archive directory naming


    # process command line parameters
    impdir = ENV['impdir'].blank? ? Dir["#{CONFIG[:contention_import_dir]}/*"].sort.last : ENV['impdir'] # take the last directory unless 'impdir' is specified on the command line, pointing to the directory containing updates
    # we assume that the uploaded directories have either an incremental suffix or a timestamp that allows that sorting directories by name results a chronological order therefore the last directory contains the most recent update
    file = ENV['file'].blank? ? File.join(impdir, 'website_data.xml') : ENV['file'] # website_data.xml is the default import file. if not, specify filename in 'file' (should be in 'impdir' and path should be relative to that)
    dbwrite = RakeUtils.str_to_boolean(ENV['dbwrite'], :default => true)        # specify 'dbwrite=false' to avoid updating the database
    filewrite = RakeUtils.str_to_boolean(ENV['filewrite'], :default => true)    # specify 'filewrite=false' to avoid updating files
    truncate = RakeUtils.str_to_boolean(ENV['truncate'], :default => true)      # specify 'truncate=false' to ...?wtfis this??
    verbose = RakeUtils.str_to_boolean(ENV['verbose'], :default => false)       # specify 'verbose=true' for extra output
    force = RakeUtils.str_to_boolean(ENV['force'], :default => false)           # specify 'force=true' for overwriting existing local files

    # stats
    total_product_reads = 0
    total_products_found = 0
    total_product_creates = 0
    total_product_updates = 0
    # #TODO add stats on file assets too

    # postpone excerpt creation
    downloads_to_create = []

    #RakeUtils.print_variable(%w(verbose file truncate), binding)
    puts "Importing Contention XML #{file} (truncate = #{truncate})..."

    xml = File.read(file)       # read in file (filesize bytes will be used)
    puts "Benchmarks:\n#{Benchmark::Tms::CAPTION}" + Benchmark.measure {
    parser, parser.string = XML::Parser.new, xml
    doc, products = parser.parse, []
    #prods = []                    # #TODO: revise what we need this for, exactly
    doc.find('//contention/products').each do |p|     # loop through imported products....
      break
      ###############################################
      xprod = XmlSimple.xml_in(p.to_s)   # read XML of a product node into an XmlSimple hash
      puts "XML Imported Product: #{xprod}" if verbose
      total_product_reads += 1

      puts "***************\nFind product by proprietary_id: #{xprod['proprietary_id']}..." if verbose
      prod = nil

      # let's try to find the product based on the proprietary id, if does not exist, create
      unless prod = Product.where(:proprietary_id => xprod['proprietary_id']).first
        puts "product with proprietary id #{xprod['proprietary_id']} not found. creating..." if verbose
        prod = create_product(xprod, dbwrite, verbose)
        total_product_creates += 1 if prod
      else
        total_products_found += 1 # if product was pre-existing in target db
      end

      # if product can be located now
      if prod
        puts "PRODUCT LOADED: \"#{prod.name}\" - (coverpage id: #{prod.id})." if verbose
        pupdates = 0      # update counter: will count attributes that need an update (if at the end of the block below it is still 0 than no update needed)

        xprod.keys.each do |xattr|    # loop through the attributes of the product being imported
          if prod.has_attribute?(xattr)   # inspect if it is a valid attribute in the coverpage database (if not, it might be a RELATED_RECORD node!)
            # 'special' attributes need special handling; (eg. collection, where id's differ but might refer to the same record)
            if ['collection_id', 'updated_at','id','user_id'].include?(xattr) # if special attribute
              case xattr
              when 'collection_id'    # for collection id, it might refer to the same record, so check by name in Collection
                # #TODO - inspect this part, kinda lost track of what was (should have been) going on here
                puts '  collection would need special checks. no data available'
                #pupdate |= true
              else  # simply ignore other 'special' attributes (user_id -> refers to the publisher in contention, skip it. updated_at -> skip it)
                puts "  #{prod.class.to_s}.#{xattr} ignoring..." if verbose
                # simply do nothing, ignoring parameter
              end
            else            # handle other ('regular') attributes in a generic way
              if xprod[xattr].to_s != prod.send(xattr).to_s   # check if the imported attribute differs from the current DB
                puts "  #{prod.class.to_s}.#{xattr} update needed! \n---\nXML: \"#{xprod[xattr].to_s}\"\nDB:  \"#{prod.send(xattr).to_s}\"" if verbose
                if dbwrite
                  prod.update_attribute(xattr, xprod[xattr].to_s)
                end
                puts "  UPDATE >> #{prod.class.to_s} #{prod.id} :: #{xattr}" if verbose

                pupdates += 1     # increase update counter
              else
                puts "  #{prod.class.to_s}.#{xattr} - no change" if verbose
              end
            end
          elsif RELATED_RECORDS.keys.include?( xattr )     # process related records (if imported attribute is included in RELATED_RECORDS)
            # skip to 2nd pass
            puts "  #{prod.class.to_s}.#{xattr} - RELATED_RECORD(s) skipping to 2nd pass..." if verbose
          else
            puts "  WARNING: #{prod.class.to_s}.#{xattr} no such attribute, nor is defined as a related record. skipping gracefully..." #if verbose
          end

        end

        if verbose      # print stats on product attribute updates
          if pupdates
            puts "  #{prod.class.to_s}: #{pupdates} update(s) were needed."
          else
            puts "  #{prod.class.to_s}: no update was needed"
          end
        end

        puts "<<<<<<<<<<<<  2ND PASS: RELATED_RECORDS" if verbose
        # 2nd pass, process the RELATED_RECORDS
        xprod.keys.each do |xattr|
          if !prod.has_attribute?(xattr) && RELATED_RECORDS.keys.include?( xattr )  # only process the RELATED_RECORD attributes
            puts "  #{prod.class.to_s}.#{xattr.capitalize} - #{xprod[xattr].count} related data entries to be processed..." if verbose
            oname = xattr.singularize.camelize # get the class name for the related records
            relrecs = prod.send(xattr) # get the related records (eg. product.editorial_reviews)

            xprod[xattr].each do |xrelrec|
              puts "  seeking #{oname}, seeking by key field: #{RELATED_RECORDS[xattr][:keyfield]}..." if verbose

              # check if there is such a record by filtering the related records
              relrecs_filtered = relrecs.where(RELATED_RECORDS[xattr][:keyfield].to_sym => xrelrec[RELATED_RECORDS[xattr][:keyfield]]).limit(1)
              relrec = relrecs_filtered.empty? ? nil : relrecs_filtered.first

              # attribute checks on related record
              if relrec     # if the related record exists
                rupdates = 0
                puts "  INFO: #{oname} found by \"#{RELATED_RECORDS[xattr][:keyfield]} => #{xrelrec[RELATED_RECORDS[xattr][:keyfield]]}\"; id = #{relrec.id}" if verbose
                xrelrec.keys.each do |xrattr|
                  unless RELATED_RECORDS[xattr][:filtered_attributes].include?(xrattr)
                    if relrec.has_attribute?(xrattr)
                      if xrelrec[xrattr].to_s != relrec.send(xrattr).to_s
                        puts "    #{oname}.#{xrattr} update needed! \n  ---\n  XML: \"#{xrelrec[xrattr].to_s}\"\n  DB:  \"#{relrec.send(xrattr).to_s}\""
                        if dbwrite
                          puts "    #{prod.class.to_s} #{prod.id} :: UPDATE >> #{oname} (#{relrec.id}) ::#{xrattr}"
                          relrec.update_attribute(xrattr, xrelrec[xrattr].to_s)
                        end
                        rupdates += 1
                      else
                        puts "    #{oname}.#{xrattr} - no changes detected." if verbose
                      end
                    else
                      puts "    WARNING: #{oname} has no such column: #{xrattr}" #if verbose # TODO or should we report these?
                    end

                  else
                    puts "    #{oname}.#{xrattr} FILTERED" if verbose
                  end
                end
                if verbose
                  if rupdates
                    puts "    #{oname}: #{rupdates} update(s) were needed"
                  else
                    puts "    #{oname}: no update was needed"
                  end
                end
              else              # if the related record does not exist, it should be created (depending on the relation type, perhaps multiple records)
                puts "  INFO: Relation to #{oname} NOT FOUND BY \"#{RELATED_RECORDS[xattr][:keyfield]} => #{xrelrec[RELATED_RECORDS[xattr][:keyfield]]}\"; assuming it is a new related record to be created." if verbose
                # #TODO if related record does not exist, we should create it
                relrec = nil        # we keep it nil for now
                case RELATED_RECORDS[xattr][:relation_type]
                when 'dependent'
                  puts "  INFO: #{xattr} specifies a DEPENDENT related record... proceed with creation" if verbose
                  create_dependent_related_record(prod, oname, xattr, xrelrec, dbwrite, verbose)

                when 'dependency'
                  create_dependency_related_record(prod, oname, xattr, xrelrec, dbwrite, verbose)

                else    # relation_type should be 'dependency' or 'dependent'. otherwise it's a malconfiguration
                  puts "  ERROR: UNKNOWN ERROR WHILE PROCESSING product.#{xattr}; PLEASE CHECK CONFIGURATION, '#{RELATED_RECORDS[xattr][:relation_type]}' is an unknown relation_type - contact developers."
                end
              end
            end # end processing a related record entry
          end # end processing related record entries
        end # end of second pass on imported product attributes


        # process any files accompanying the record
        if File.exist?( File.join(impdir, "#{prod.isbn}.pdf"))
          xef = File.join(impdir, "#{prod.isbn}.pdf")

          puts "  EBOOK ASSET FOUND: #{xef}"
          if prod.respond_to?('download')         # if Title
            if prod.download                        # has download
              wef = prod.download.public_filename   # get download public filename
              puts "  INFO: ebook exists in coverpage; id: #{prod.download.id} #{wef} - #{prod.download.size}..."
              puts "  INFO: File sizes differ. Imported #{File.size(xef)} (created: #{File.ctime(xef)}) Coverpage: #{File.size(wef)} (created: #{File.ctime(wef)})" if File.exist?(wef) && File.size(xef) != File.size(wef)
              puts "  INFO: File hashes differ. Imported #{File.size(xef)} (created: #{File.ctime(xef)}) Coverpage: #{File.size(wef)} (created: #{File.ctime(wef)})" if File.exist?(wef) && filehash(xef) != filehash(wef)
              puts "  INFO: ebook seems corrupted; file is missing. (#{wef})" unless File.exist?(wef)

              # #TODO first archive the existing ebook file!!
              if File.exist?(wef)
                if File.size(xef) != File.size(wef)
                  aef = File.join(Rails.root.to_s, CONFIG[:contention_archives_dir], timestamp, File.basename(inf))
                  puts "  ARCHIVING ORIGINAL TO: #{aef}"
                  archive_file( wimf, aimf ) if filewrite
                else
                  puts "  SEEMS LIKE THERE IS NO DIFFERENCE BETWEEN THE LOCAL & IMPORTED FILE"
                end
              end

              if !File.exist?(wef) || File.size(xef) != File.size(wef)
                if filewrite && dbwrite       # updating existing ebooks requires write access to both to the db and filesystem
                  update_file(xef, wef, force)   # enable overwrite. update file will only update if size & hash differ...

                  if File.size(xef) != prod.download.size   # check if different files (file sizes mismatch)
                    # #TODO this must be re-tested a few times with PDF's created with test scribd fu account (original data refers to real childsworld scribd data!!!)
                    # MAKE SURE TO ONLY USE TEST IMPORT WITH TEST SCRIBD ACCOUNT OTHERWISE REAL EXCERPTS CAN GET CORRUPTED...
                    prod.download.update_attribute(:size, File.size(xef))
                    # #TODO: first of all, check how prod.download.save deals with scribd-fu
                    #prod.download.save   #TODO : enable saving the file, update the download's size in db
                    puts "  INFO: copied file sizes differs from DB. #{File.size(xef) != prod.download.reload.size ? "FIX FAILED; UPDATE DB!" : "fixed."}" if verbose
                  else
                    puts "  INFO: copied file sizes matches to DB. (#{File.size(xef)}) ok." if verbose
                  end
                else
                  puts "  DEBUG: SHOULD HAVE COPIED '#{xef}' to '#{wef}' and should have updated database....."
                end
              end
            else                                    # if no download record in coverpage
              puts "  INFO: ebook does not exist in coverpage." if verbose
              if prod.respond_to?('create_download_with_local_file')
                #pd = prod.create_download_with_local_file(xef)
                downloads_to_create << { :product_id => prod.id, :file => xef }
                puts "  INFO: ebook should be created in DB and filesystem." if verbose
              else
                puts "  ERROR: #{prod.class.to_s} IS NOT RESPONDING TO 'create_download_with_local_file'... NO EBOOK CREATED. NO FILE COPIED."
              end
            end
          end
        end     # done processing any EBOOK ASSETS

        # Process WEBSITE IMAGES (should be uploaded in the import directory with '<ISBN>_<AssetType>_<AssetSize>.jpg' file name)
        image_files = Dir["#{File.join(impdir)}/#{prod.isbn}_*.jpg"].sort   # all files to be processed belonging to the main product being imported

        image_files.each { |inf|
          (iisbn, itype, isize) = File.basename(inf).gsub(File.extname(inf), "").split('_') # resolve asset type from filename
          if File.exist?( inf )       # #TODO : do we really need this check here????!
            puts "  * FOUND ASSET : ISBN #{iisbn} TYPE : #{itype} SIZE: #{isize}" if verbose
            puts "  HAS IMAGE? #{prod.has_image?(itype.pluralize,isize) ? 'yes' : 'no' }" if verbose # check if the product has such an image defined in local DB/FS
            wimf = File.join(Rails.root.to_s, CONFIG[:website_images_dir], prod.web_image_path(itype.pluralize, isize))

            # if the file exists and is different from the new one, let's archive it first
            if File.exist?(wimf)
              if File.size(inf) != File.size(wimf)
                aimf = File.join(Rails.root.to_s, CONFIG[:contention_archives_dir], timestamp, File.basename(inf))
                puts "  ARCHIVING ORIGINAL TO: #{aimf}"
                archive_file( wimf, aimf ) if filewrite
              else
                puts "  SEEMS LIKE THERE IS NO DIFFERENCE BETWEEN THE LOCAL & IMPORTED FILE"
              end
            end

            # if it's a new or different file, let's 'import' it
            if !File.exist?(wimf) || File.size(inf) != File.size(wimf)
              if filewrite
                update_file( inf, wimf, force )
                puts "  <<<<<<<<<<<<< UPDATED FILE, RECHECK PRODUCT.HAS_IMAGE? - #{prod.has_image?(itype.pluralize,isize) ? 'yes' : 'no' }" if verbose
              elsif verbose
                puts "  DEBUG: SHOULD HAVE COPIED '#{inf}' to '#{wimf}'....."
              end
            end

            # CHECKS #TODO we can drop this part when done testing
            if File.exist?(wimf)
              if File.size(inf) != File.size(wimf)
                puts "  filesize difference; imported: #{File.size(inf)} (created: #{File.ctime(inf)}), existing: #{File.size(wimf)} (created: #{File.ctime(wimf)})"
              else
                puts "  filesizes match. #{File.size(wimf)}"
              end
            else
              puts " ERROR: #{wimf} should be there but it is not." if filewrite
            end
          end
        }             # processing WEBSITE IMAGES

        #prods << prod      # #TODO seems like we're saving it for nothing, wasting ram
      else      # should be dead-code (unless invalid XML passed)
        puts "  ERROR: product with proprietary id #{xprod['proprietary_id']} not found. Creation failed. Invalid XML??"
      end
      #########################################

    end               # end looping though imported products.

    puts "done.\n  Total Product Nodes: #{total_product_reads}\n  Total Products Found: #{total_products_found}\n  Total Product Creations: #{total_product_creates}\n  Total Product Updates: #{total_product_updates}" if verbose
    puts "#{downloads_to_create.size} downloads to be created..."
    }.to_s      # end of Benchmarking

  end     # import task


end   # namespace
