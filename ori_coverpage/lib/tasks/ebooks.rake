namespace :ebooks do
  require 'pdf'
  require 'file_tool'
  require 'rake_utils'

  IN_DIR = Rails.root.join('tmp/printpdfs/in')
  IN_SUBDIRS = %w(covers interiors)
  OUT_DIR = Rails.root.join('tmp/printpdfs/out')
  OUT_SUBDIRS = %w(fronts backs ints ends merges)
  ARCHIVE_DIR = Rails.root.join('tmp/printpdfs/archive')

  desc "Fix mismatched excerpts. Optional: debug, verbose, ids."
  task :fix_mismatched => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    if ENV['ids'].blank?
      ids = nil
      excerpts = Excerpt
    else
      ids = ENV['ids'].split(',').map{|i| i.strip}
      excerpts = Excerpt.where("id IN (?)", ids)
    end
    fix = Coverpage::Utils.str_to_boolean(ENV['fix'], :default => false)
    Coverpage::Utils.print_variable(%w(debug verbose ids), binding)
    solutions = []
    excerpts.all.each do |excerpt|
      FEEDBACK.important("#{excerpt.title.name} (#{excerpt.id})") if excerpt.title
      unless title = excerpt.title
        FEEDBACK.error("No associated title (excerpt.id = #{excerpt.id})")
        next
      end
      unless doc = excerpt.ipaper_document
        FEEDBACK.error("No scribd document (excerpt.id = #{excerpt.id})")
        next
      end
      if title.name != doc.title
        FEEDBACK.error("Names do NOT match (excerpt.id = #{excerpt.id})")
        FEEDBACK.important("  doc.title = #{doc.title}") if verbose
        FEEDBACK.important("  title.name (#{title.id}) = #{title.name}") if verbose
        if new_title = Title.find_by_name(doc.title)
          FEEDBACK.important("  SOLUTION: #{new_title.name} (#{new_title.id}) << excerpt") if verbose
          solutions << excerpt.id if debug
          new_title.excerpt = excerpt unless debug
        end
      end
    end
    FEEDBACK.important("solutions = #{solutions.inspect}") if solutions.any?
  end

  desc "Apply metadata to ebook. Optional: debug, verbose, source, isbns."
  task :apply_metadata => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    source = ENV['source'].blank? ? CONFIG[:ebook_import_source_dir] : ENV['source']
    dir = Rails.root.join(source)
    if ENV['isbns'].blank?
      isbns = Dir.glob(File.join(dir, "*.pdf")).map{|path| File.basename(path, '.pdf')}
    else
      isbns = ENV['isbns'].split(',').map{|i| i.strip}
    end
    Coverpage::Utils.print_variable(%w(debug verbose source isbns), binding)
    isbns.each do |isbn|
      if product = Product.find_by_isbn(isbn)
        FEEDBACK.print_record(product)
        path = File.join(dir, "#{product.isbn}.pdf")
        product.apply_metadata(path)
      else
        FEEDBACK.error("Product not found '#{isbn}'")
      end
    end
  end

  desc "Create ebook from press sheet and interior. Optional: debug, verbose, archive, isbns, padding, metadata."
  task :create => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    archive = Coverpage::Utils.str_to_boolean(ENV['archive'], :default => true)
    metadata = Coverpage::Utils.str_to_boolean(ENV['metadata'], :default => true)
    padding = ENV['padding'].to_i > 0 ? ENV['padding'].to_i : 81
    if ENV['isbns'].blank?
      isbns = Dir.glob(File.join(IN_DIR, "interiors/*.pdf")).map{|path| File.basename(path, '.pdf')}
    else
      isbns = ENV['isbns'].split(',').map{|i| i.strip}
    end
    Coverpage::Utils.print_variable(%w(debug verbose archive isbns padding metadata), binding)
    create_dirs(debug, verbose)
    isbns.each do |isbn|
      create_by_isbn(isbn, padding, archive, metadata, debug, verbose)
    end
  end

  def create_by_isbn(isbn, padding, archive, metadata, debug, verbose)
    product = Coverpage::Utils.isbn_to_product(isbn)
    Coverpage::Utils.print_product(product) if verbose
    in_cover = File.join(IN_DIR, 'covers', "#{isbn}.pdf")
    in_interior = File.join(IN_DIR, 'interiors', "#{isbn}.pdf")
    RakeUtils.test_file(in_cover)
    RakeUtils.test_file(in_interior)
    out_front = File.join(OUT_DIR, 'fronts', "#{isbn}.pdf")
    out_back = File.join(OUT_DIR, 'backs', "#{isbn}.pdf")
    out_int = File.join(OUT_DIR, 'ints', "#{isbn}.pdf")
    out_end = File.join(OUT_DIR, 'ends', "#{isbn}.pdf")
    out_merge = File.join(OUT_DIR, 'merges', "#{isbn}.pdf")
    create_front(product, in_cover, out_front, padding, debug, verbose)
    create_back(product, in_cover, out_back, padding, debug, verbose)
    create_int(in_interior, out_int, debug, verbose)
    create_end(out_int, out_end, debug, verbose)
    create_merge([out_front, out_end, out_int, out_end, out_back], out_merge)
    if metadata && File.exist?(out_merge) && product.is_a?(Title)
      product.apply_metadata(out_merge)
    end
    FileTool.remove(out_front, out_back, out_int, out_end)
    if archive == true
      FileUtils.mv(in_cover, File.join(ARCHIVE_DIR, 'covers'), :noop => debug, :verbose => verbose)
      FileUtils.mv(in_interior, File.join(ARCHIVE_DIR, 'interiors'), :noop => debug, :verbose => verbose)
    end
  end
  
  desc "Create front cover from press sheet. Required: isbn. Optional: debug, verbose, padding."
  task :create_front => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    isbn = Coverpage::Utils.impose_requirement(ENV, 'isbn')
    product = Coverpage::Utils.isbn_to_product(isbn)
    padding = ENV['padding'].to_i > 0 ? ENV['padding'].to_i : 81
    Coverpage::Utils.print_variable(%w(debug verbose isbn padding), binding)
    source = File.join(IN_DIR, 'covers', "#{isbn}.pdf")
    target = File.join(OUT_DIR, 'fronts', "#{isbn}.pdf")
    Coverpage::Utils.print_product(product) if verbose
    create_front(product, source, target, padding, debug, verbose)
  end

  def create_front(product, source, target, padding, debug, verbose)
    pdf = Pdf.new(source, :debug => debug, :verbose => verbose)
    unless !pdf.error && pdf.press_to_front(target, product.default_format.width, product.default_format.height, padding)
      FEEDBACK.error("Failed to create front")
      exit
    end
  end

  desc "Create back cover from press sheet. Required: isbn. Optional: debug, verbose, padding."
  task :create_back => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    isbn = Coverpage::Utils.impose_requirement(ENV, 'isbn')
    product = Coverpage::Utils.isbn_to_product(isbn)
    padding = ENV['padding'].to_i > 0 ? ENV['padding'].to_i : 81
    Coverpage::Utils.print_variable(%w(debug verbose isbn padding), binding)
    source = File.join(IN_DIR, 'covers', "#{isbn}.pdf")
    target = File.join(OUT_DIR, 'backs', "#{isbn}.pdf")
    Coverpage::Utils.print_product(product) if verbose
    create_back(product, source, target, padding, debug, verbose)
  end
  
  def create_back(product, source, target, padding, debug, verbose)
    pdf = Pdf.new(source, :debug => debug, :verbose => verbose)
    unless !pdf.error && pdf.press_to_back(target, product.default_format.width, product.default_format.height, padding)
      FEEDBACK.error("Failed to create back")
      exit
    end
  end

  desc "Crop interior. Required: isbn. Optional: debug, verbose."
  task :create_int => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    isbn = Coverpage::Utils.impose_requirement(ENV, 'isbn')
    product = Coverpage::Utils.isbn_to_product(isbn)
    Coverpage::Utils.print_variable(%w(debug verbose isbn), binding)
    source = File.join(IN_DIR, 'interiors', "#{isbn}.pdf")
    target = File.join(OUT_DIR, 'ints', "#{isbn}.pdf")
    Coverpage::Utils.print_product(product) if verbose
    create_int(source, target, debug, verbose)
  end
  
  def create_int(source, target, debug, verbose)
    pdf = Pdf.new(source, :debug => debug, :verbose => verbose)
    unless !pdf.error && pdf.interior(target)
      FEEDBACK.error("Failed to create int")
      exit
    end
  end

  desc "Create end sheet. Required: isbn. Optional: debug, verbose."
  task :create_end => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    isbn = Coverpage::Utils.impose_requirement(ENV, 'isbn')
    product = Coverpage::Utils.isbn_to_product(isbn)
    Coverpage::Utils.print_variable(%w(debug verbose isbn), binding)
    source = File.join(OUT_DIR, 'ints', "#{isbn}.pdf")
    target = File.join(OUT_DIR, 'ends', "#{isbn}.pdf")
    Coverpage::Utils.print_product(product) if verbose
    create_end(source, target, debug, verbose)
  end

  def create_end(source, target, debug, verbose)
    pdf = Pdf.new(source, :debug => debug, :verbose => verbose)
    unless !pdf.error && pdf.endsheet(target)
      FEEDBACK.error("Failed to create end")
      exit
    end
  end
  
  desc "Merge front, back, end and int. Required: isbn. Optional: debug, verbose."
  task :create_merge => :environment do
    debug = Coverpage::Utils.str_to_boolean(ENV['debug'], :default => false)
    verbose = (debug || Coverpage::Utils.str_to_boolean(ENV['verbose'], :default => true))
    isbn = Coverpage::Utils.impose_requirement(ENV, 'isbn')
    product = Coverpage::Utils.isbn_to_product(isbn)
    Coverpage::Utils.print_variable(%w(debug verbose isbn), binding)
    out_front = File.join(OUT_DIR, 'fronts', "#{isbn}.pdf")
    out_back = File.join(OUT_DIR, 'backs', "#{isbn}.pdf")
    out_int = File.join(OUT_DIR, 'ints', "#{isbn}.pdf")
    out_end = File.join(OUT_DIR, 'ends', "#{isbn}.pdf")
    out_merge = File.join(OUT_DIR, 'merges', "#{isbn}.pdf")
    Coverpage::Utils.print_product(product) if verbose
    create_merge([out_front, out_end, out_int, out_end, out_back], out_merge)
  end

  def create_merge(sources, target)
    sources = [sources] unless sources.is_a?(Array)
    cmd = "#{CONFIG[:pdftk]} #{sources.join(' ')} output #{target}"
    ext = FileTool.file_ext(target) || "unknown format"
    FEEDBACK.verbose("  Merging files to create ebook...")
    FEEDBACK.debug(cmd)
    unless system(cmd)
      FEEDBACK.error "Failed to merge files to create ebook #{target}"
      exit
    end
  end
  
  def create_dirs(debug = false, verbose = true)
    IN_SUBDIRS.each do |dir|
      FileUtils.mkdir_p(File.join(IN_DIR, dir), :noop => debug, :verbose => verbose)
      FileUtils.mkdir_p(File.join(ARCHIVE_DIR, dir), :noop => debug, :verbose => verbose)
    end
    OUT_SUBDIRS.each do |dir|
      FileUtils.mkdir_p(File.join(OUT_DIR, dir), :noop => debug, :verbose => verbose)
    end
  end
  
end

