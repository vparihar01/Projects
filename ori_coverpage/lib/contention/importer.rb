# Contention::Importer
#
# functions for importing XML & asset files from Contention to maintain Coverpage catalog
#
module Contention
  module Importer
    require 'xmlsimple'   # for parsing XML in a simple way (get a hash from the XML)
    require 'xml'         # for parsing only certain nodes at a time (saves memory)
    require 'md5'         # for generating md5hashes

    REL_TYPES = [ 'dependent', 'dependency' ]   # dependent reclated records must be created after, dependency ones before the product

    # main XML nodes are Products; define related records in the RELATED_RECORDS hash below
    # <tt>hash keys:</tt> table name where product related records are
    # <tt>hash value:</tt> struct (hash) with the following keys
    # <tt>:keyfield</tt> - specify the local key in the related record table that matches id's in the received data
    # <tt>:through</tt> - if product assignment is not direct, specify the assignment table here
    # <tt>:filtered_attributes</tt> - specify any fields that should be ignored during import (no checks on, no updates of)
    #
    # see also: module Contention::DataAssetDistribution::XmlPackaging::Coverpage - RELATED_RECORDS (code must be in sync)
    #
    # #TODO: 'updated_a' is updated_at but temporarily checks are enabled. add the missing 't' when done testing...
    RELATED_RECORDS = { 'categories' => { :relation_type => 'dependency', :keyfield => 'proprietary_id', :through => 'categories_products', :filtered_attributes => ['id','updated_a'] },
                        'assemblies' => { :relation_type => 'dependent', :keyfield => 'proprietary_id', :through => 'assembly_assignments', :filtered_attributes => ['collection_id', 'id','user_id','updated_a'] },
                        'bisac_subjects' => { :relation_type => 'dependency', :keyfield => 'code', :through => 'bisac_assignments', :filtered_attributes => ['proprietary_id','updated_a'] },
                        'contributors' => { :relation_type => 'dependency', :keyfield => 'proprietary_id', :through => 'contributor_assignments', :assignment_attributes => [ 'role' ], :filtered_attributes => ['id','user_id','updated_a'] },
                        'product_formats' => { :relation_type => 'dependent', :keyfield => 'format_id', :through => nil, :filtered_attributes => ['id','proprietary_id','updated_a','product_id'] },
                        'editorial_reviews' => { :relation_type => 'dependency', :keyfield => 'proprietary_id', :through => 'editorial_reviews_products', :filtered_attributes => ['updated_a'] },
                        'related_products' => { :relation_type => 'dependent', :keyfield => 'proprietary_id', :through => 'related_products_assignments', :filtered_attributes => ['updated_a'] },
                        'collections' => { :relation_type => 'dependency', :keyfield => 'proprietary_id', :through => nil, :filtered_attributes => ['updated_a'] } }.freeze

    # updates a file in the filesystem
    # <tt>newfile</tt> - path to source file
    # <tt>oldfile</tt> - path to destination file
    # <tt>overwrite</tt> - overwrite if exists if true
    # <tt>hardlink</tt> - pass true/false to specify behaviour explicitly (otherwise behaves as specified in CONFIG[:contention_hardlink_assets])
    def update_file( newfile = nil, oldfile = nil, overwrite = false, hardlink = nil )
      # verify arguments
      raise ArgumentError, "newfile ('#{newfile}') must be a valid file" if newfile.nil? || !File.exist?(newfile)
      raise ArgumentError, "oldfile ('#{oldfile}') must be a valid path" if oldfile.nil? || oldfile.blank?
      raise ArgumentError, "oldfile ('#{oldfile}') exists, but overwrite is false." if File.exist?(oldfile) && !overwrite

      filewrite = true       # we shall write the file. if we should not, set it to false
      if File.exist?(oldfile)   # if we have the old file in place, we might not want to overwrite
        if File.size(newfile) == File.size(oldfile) &&  # check if it was the same file (size mismatch)
              filehash(newfile) == filehash(oldfile)    # besides file size, check the file hash as well (checksum mismatch)
          filewrite = false     # should not overwrite if no change
        end
      end
      
      if filewrite          # shall we write? (new or different)
        FileUtils.mkdir_p(File.dirname(oldfile)) unless File.exist?(File.dirname(oldfile))  # make sure the receiving directory is there
        if (CONFIG[:contention_hardlink_assets] && hardlink.nil?) || hardlink == true
          Rails.logger.debug 'IMPORTER: using file hardlinking'
          FileUtils.link(newfile, oldfile)   
        else
          Rails.logger.debug 'IMPORTER: using file copy'
          FileUtils.copy_file(newfile, oldfile)
        end
      end
      filewrite     # return if file should have been written (counting on there is an error raised if mkdir_p or link fails)
    end

    # a wrapper around update file, with certain settings (force, copy iso. hardlink)
    # <tt>src</tt> - source file
    # <tt>dest</tt> - destination file
    #
    # use of file copy is a must. if we would hardlink the archive, it would get modified
    # if the original gets modified -- this does not occur in case the original gets
    # overwritten by file 'copy --force'
    def archive_file( src, dest )
      update_file( src, dest, true, false )
    end
    
    # generates an MD5 hash of the file
    def filehash(filename)
      MD5.new(File.new(filename, 'r').read).hexdigest
    end

    def process_related_record(prod, xml_relrec)
      
    end

    # create_product - creates a product based on Hash with XML attributes
    # <tt>xprod</tt> - Hash with the product attributes (from XML)
    def create_product(xprod, dbwrite = true, verbose = true)
      FEEDBACK.debug "CREATE PRODUCT CALLED."
      # #TODO: create product
      pattr = {}    # will collect attributes of the product record (some XML attributes are related records, etc.)

      # 1st pass - collect attributes for the product record (-> pattr)
      xprod.keys.each do |xattr|    # loop through the attributes of the product being imported
        if Product.column_names.include?(xattr)   # inspect if it is a valid attribute in the coverpage database (if not, it might be a RELATED_RECORD node!)
          # 'special' attributes need special handling; (eg. collection, where id's differ but might refer to the same record)
          if ['collection_id', 'updated_at','id','user_id'].include?(xattr) # if special attribute
            case xattr
            when 'collection_id'    # for collection id, it might refer to the same record, so check by name in Collection
              # #TODO - inspect this part, kinda lost track of what was (should have been) going on here
              puts '  collection would need special checks. no data available'
              #pupdate |= true
            else  # simply ignore other 'special' attributes (user_id -> refers to the publisher in contention, skip it. updated_at -> skip it)
              puts "  #{xprod['type'].to_s}.#{xattr} ignoring..." if verbose
              # simply do nothing, ignoring parameter
            end
          else            # handle other ('regular') attributes in a generic way
            puts "  #{xprod['type'].to_s}.#{xattr} to be included: \n---\nXML: \"#{xprod[xattr].to_s}\"" if verbose
            pattr[xattr] = xprod[xattr]         # save the attribute
          end
        elsif RELATED_RECORDS.keys.include?( xattr )     # process related records (if imported attribute is included in RELATED_RECORDS)
          # skip to 2nd pass
          puts "  #{xprod['type'].to_s}.#{xattr} - is a RELATED_RECORD skipping to 2nd pass..." if verbose
        else
          puts "  WARNING: #{xprod['type'].to_s}.#{xattr} no such attribute, nor is defined as a related record. skipping gracefully..." #if verbose
        end
      end
      # we now have the primary attributes in pattr
      puts "  CREATE: #{xprod['type'].to_s} with attributes: \n---\"#{pattr}\"" if verbose
      prod = xprod['type'].classify.constantize.create(pattr)

      if prod
        puts "ok"
      else
        puts "failed."
      end

      prod    # return the Product
    end


    # creates a dependent (normally 'product has_...') record
    # <tt>prod</tt> the Product that should have the dependent record
    # <tt>oname</tt> the Object name
    # <tt>xattr</tt> the product XML attribute
    # <tt>xrelrec</tt> the Hash (from XML) that holds the related dependent record's attributes
    def create_dependent_related_record(prod, oname, xattr, xrelrec, dbwrite = true, verbose = true)

      xrattrs = {}
      xrelrec.keys.each do |xrattr|
        unless RELATED_RECORDS[xattr][:filtered_attributes].include?(xrattr)
          if xattr.classify.constantize.column_names.include?(xrattr)
              puts "  INFO: #{xattr.classify}.#{xrattr} - usable attribute found" if verbose
              xrattrs[xrattr] = xrelrec[xrattr]
          else
            puts "    WARNING: #{oname} has no such column: #{xrattr}" #if verbose # TODO or should we report these?
          end

        else
          puts "  INFO: #{oname}.#{xrattr} FILTERED" if verbose
        end
      end

      # add product id (check column names automatically, thus the block :()
      if xattr.classify.constantize.column_names.include?("#{prod.class.to_s.underscore}_id")
        xrattrs["#{prod.class.to_s.underscore}_id"] = prod.id
        puts "  INFO: '#{prod.class.to_s.underscore}_id' used as reference to product..." if verbose
      elsif xattr.classify.constantize.column_names.include?('product_id')
        xrattrs["product_id"] = prod.id
        puts "  INFO: 'product_id' used as reference to product by fallback..." if verbose
      else
        puts "  ERROR: surprisingly #{xattr.classify} has no column #{prod.class.to_s.underscore}_id (NOR product_id)"
      end

      puts "data..........#{xrelrec} -> #{xrattrs}.............. " if verbose
      begin
        xattr.classify.constantize.create(xrattrs)
      rescue Exception => e
        puts "EXCEPTION: #{e}"
        raise e
      end
    end


    # creates a dependency (normally 'product belongs_to...') record
    # <tt>prod</tt> the Product that should have the dependent record
    # <tt>oname</tt> the Object name
    # <tt>xattr</tt> the product XML attribute
    # <tt>xrelrec</tt> the Hash (from XML) that holds the related dependent record's attributes
    def create_dependency_related_record(prod, oname, xattr, xrelrec, dbwrite = true, verbose = true)
      puts "  INFO:  #{xattr} specifies a DEPENDENCY related record (normally should have been created before the product)... further checks needed..." if verbose
      # #TODO should 1st check if the relationship is direct or through an assignments table; perhaps the real related record exists only assignment is missing
      unless RELATED_RECORDS[xattr][:through].nil?    # if relationship is established via an assignment table
        potrelrecs = xattr.classify.constantize.where( { RELATED_RECORDS[xattr][:keyfield] => xrelrec[RELATED_RECORDS[xattr][:keyfield]] } ).all
        potrelrec = nil
        if potrelrecs.empty?    # #TODO if the related record base is not found, create it
          puts "  INFO: missing related record to be assigned. first must create related record base, then assignment" if verbose
          # #TODO - check if dbwrite
          # collect attributes to be included in creation (omit filtered attributes)
          xrattrs = {}
          relclass = xattr.classify.constantize
          puts "  INFO: inspecting #{relclass}" if verbose
          xrelrec.keys.each do |xrattr|
            unless RELATED_RECORDS[xattr][:filtered_attributes].include?(xrattr)
              if relclass.column_names.include?(xrattr)
                  puts "  INFO: #{xattr.classify}.#{xrattr} - usable attribute found" if verbose
                  xrattrs[xrattr] = xrelrec[xrattr]
              else
                puts "    WARNING: #{oname} has no such column: #{xrattr}" #if verbose # TODO or should we report these?
              end

            else
              puts "  INFO: #{oname}.#{xrattr} FILTERED" if verbose
            end
          end

          # now we have the base related record attributes, let's create it
          potrelrec = relclass.create(xrattrs)
          if potrelrec
            puts "    INFO: created #{xattr.classify} with attributes: #{xrattrs}." if verbose
          else
            puts "    ERROR: failed to create #{xattr.classify} with attributes: #{xrattrs}."
          end

        elsif potrelrecs.count == 1
          potrelrec = potrelrecs.first
          puts "found the related record, only assignment has to be created." if verbose
        else      # this should not happen, but...
          # we don't assign a record to 'potrelrec'
          puts "  ERROR: ambigous reference to  #{xattr}, multiple (#{potrelrecs.count}) records found..."
        end

        if potrelrec # if we found/created the record the assignment must rely on...
          # #TODO: create assignment
          begin
            puts "we have a base record #{potrelrec.class.to_s}, should create assignment record in #{RELATED_RECORDS[xattr][:through]}" if verbose
            # #TODO: check dbwrite
            # fill out the assignment record's default columns (id's)
            assignment_attributes = {}
            # first set the product id (or equivalent)
            # the following statement might result an exception, when there is no separate model for the assignment records;
            # exception will be catched later on (see rescue) and if possible, an accessor on product will be used
            if RELATED_RECORDS[xattr][:through].classify.constantize.column_names.include?("#{prod.class.to_s.underscore}_id")
              assignment_attributes["#{prod.class.to_s.underscore}_id"] = prod.id
              puts "  INFO: '#{prod.class.to_s.underscore}_id' used as reference to product..." if verbose
            elsif RELATED_RECORDS[xattr][:through].classify.constantize.column_names.include?('product_id')
              assignment_attributes["product_id"] = prod.id
              puts "  INFO: 'product_id' used as reference to product by fallback..." if verbose
            else
              puts "  ERROR: surprisingly #{RELATED_RECORDS[xattr][:through].classify} has no column #{prod.class.to_s.underscore}_id (NOR product_id)"
            end
            # then the related record
            if RELATED_RECORDS[xattr][:through].classify.constantize.column_names.include?("#{potrelrec.class.to_s.underscore}_id")
              assignment_attributes["#{potrelrec.class.to_s.underscore}_id"] = potrelrec.id
              puts "  INFO: '#{potrelrec.class.to_s.underscore}_id' used as reference to #{potrelrec.class.to_s}..." if verbose
            else
              puts "  ERROR: surprisingly #{RELATED_RECORDS[xattr][:through].classify} has no column #{potrelrec.class.to_s.underscore}_id"
            end
            puts "data..........#{xrelrec[RELATED_RECORDS[xattr][:through]].class.to_s}.............. #{xrelrec[RELATED_RECORDS[xattr][:through]]}"
            # add any more columns specified via the :assignment_attributes
            RELATED_RECORDS[xattr][:assignment_attributes].each do |aa|
              puts "PROCESSING #{aa}"
              assignment_attributes[aa] =
                Hash[*xrelrec[RELATED_RECORDS[xattr][:through]]][aa]
            end if RELATED_RECORDS[xattr].keys.include?(:assignment_attributes) && !RELATED_RECORDS[xattr][:assignment_attributes].blank?
            puts "  DEBUG: .......................................................\n    #{assignment_attributes}\n  ................................................"
            # #TODO check dbwrite
            RELATED_RECORDS[xattr][:through].classify.constantize.create(assignment_attributes)
            puts "  DEBUG: *******************************************************\n    #{xrelrec[RELATED_RECORDS[xattr][:through]]}\n  *************************************"

          rescue Exception => e                                 # there might not be a separate model for assignments, exception will be catched
            if e.message.include?('uninitialized constant')       # this is how we detect that there is no separate model for the assignments
              # the assignments table has no model, will try to access using an accessor on product
              puts "  INFO: #{RELATED_RECORDS[xattr][:through]} has no model. will try it as an accessor on product" if verbose

              # #TODO check dbwrite
              if prod.respond_to?(RELATED_RECORDS[xattr][:through])
                puts "  INFO: #{prod.class.to_s} - #{potrelrec.class.to_s} relation will be established via #{prod.class.to_s}.#{RELATED_RECORDS[xattr][:through]} (#{prod.send(RELATED_RECORDS[xattr][:through]).class.to_s})" if verbose
                prod.send(RELATED_RECORDS[xattr][:through]) << potrelrec      # push the related record into the assignments on product
              elsif prod.respond_to?(xattr)
                puts "  INFO: #{prod.class.to_s} - #{potrelrec.class.to_s} relation will be established via #{prod.class.to_s}.#{xattr} (#{prod.send(xattr).class.to_s})" if verbose
                prod.send(xattr) << potrelrec
              else
                puts "  ERROR: don't know how to assign #{potrelrec.class.to_s} to #{prod.class.to_s} /should be via #{RELATED_RECORDS[xattr][:through]}/"
              end

            else
              puts "  EXCEPTION #{e} - RE-RAISING..."
              raise e
            end
          end

        else
          puts "  ERROR: can not establish assignment with  #{xattr}."
        end

        # #TODO create assignment record between the related base record and the product
      else                                            # if relationship is direct (no :through table specified)
        # just create the related record and update product; we have no such case
        puts "  ERROR: unexpected execution branch; DEPENDENCY RECORD WITHOUT ASSIGNMENTS TABLE - contact developers."
      end
    end




    

  end # Module
end