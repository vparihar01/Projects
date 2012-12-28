module Coverpage
  # = Coverpage Themes Module
  # TODO: clean up commented debug statements once going for a release (eventually can be converted into debug logs)
  module Themes
    # provides Themes for Coverpage deployments

    # Return an array of installed themes
    def self.themes
      @@available_themes ||= load_themes
    end

    # Causes to reload themes from the themes directory
    def self.reload
      @@available_themes = load_themes
    end

    # Returns the theme specified (if such theme is loaded)
    # Parameters:
    # * +id+ - the id of the theme (must be the directory name in public/themes)
    #
    # Example:
    #   @current_theme = Coverpage::Themes.theme('default')
    #
    def self.theme(id)
      themes.find {|t| t.id == id}
    end

    # Coverpage Theme Class
    #
    # provides a simple interface to themes installed in 'public/themes'
    class Theme
      attr_reader :name, :dir

      # set name from path name
      def initialize(path)
        @dir = File.basename(path)
        @name = @dir.humanize
      end

      # Directory name used as the theme id
      def id; dir end

      # Returns the public path (relative to 'public/')
      def public_path
        "themes/#{self.dir}"
      end

      def <=>(theme)
        name <=> theme.name
      end
    end

    private

    # Loads themes from the theme directory ("<app>/public/themes")
    #
    # a theme must have at least a custom 'public.css' or 'application.css' in
    # '<app>/public/themes/<theme>/stylesheets/' in order to be recognized as a theme
    def self.load_themes
      dirs = Dir.glob("#{Rails.root.to_s}/public/themes/*").select do |f|
        #puts "Coverpage::Themes: Checking #{f}...."
        File.directory?(f) && (File.exist?("#{f}/stylesheets/public.css") || File.exist?("#{f}/stylesheets/application.css"))
      end
      #puts "Coverpage::Themes::Theme.load_themes :: valid themes:"
      #dirs.each { |td| puts "\t *theme dir: #{td}"}
      dirs.collect {|dir| Theme.new(dir)}.sort
    end
  end
end

# Customization of Rails ActionView::Helpers::AssetTagHelper
# compatible with Rails 3.0.3
# TODO: add tests for this library!!!! (so any later incompatibilities can be spotted by tests)
module ActionView # :nodoc:
  module Helpers # :nodoc:
    module AssetTagHelper # :nodoc:

      private
        # we will call the original compute_public_path from our redefined one
        alias_method :old_compute_public_path, :compute_public_path

        # a rewrite of compute_public_path -- that is used by all image_tag, stylesheet_tag, etc.
        # helper methods. patching this helper method will support transparent
        # usage of Themes
        def compute_public_path(source, dir, ext = nil, include_host = true)
          return source if is_uri?(source)
          @current_theme ||= Coverpage::Themes.theme(CONFIG[:theme])
          #puts "COMPUTE_PUBLIC_PATH: src: #{source} dir: #{dir} ext: #{ext}; THEME: #{@current_theme}"

          # if we have a version of the file requested in our current theme, than we should go for that one
          if File.exists?(File.join(config.assets_dir, @current_theme.public_path, dir, "#{source}#{ext.nil? ? "" : "." + ext}"))
            #puts "COMPUTE_PUBLIC_PATH: THEME FILE FOUND FOR '#{dir}/#{source}.#{ext}': #{File.join(config.assets_dir, @current_theme.public_path, dir, "#{source}.#{ext}")}"
            dir = "#{@current_theme.public_path}/#{dir}"  # send the theme directory instead of the original one
          else
            #puts "COMPUTE_PUBLIC_PATH: THEME FILE DOESNT EXIST FOR '#{dir}/#{source}.#{ext}': #{File.join(config.assets_dir, @current_theme.public_path, dir, "#{source}.#{ext}")}"
          end

          source = old_compute_public_path(source, dir, ext, include_host)
          #puts "COMPUTE_PUBLIC_PATH: will use ==============> #{source}"
          source
        end
    end
    
  end
end

# Customization of Rails ActionView::PathResolver
# compatible with Rails 3.0.3
# TODO: add tests for this library!!!! (so any later incompatibilities can be spotted by tests)
module ActionView # :nodoc:
  class PathResolver # :nodoc:
    private
    # we're gonna patch 'query' for loading custom templates from themes, so alias the original
    alias_method :old_query_for_themes, :query

    # provides finding templates in theme directories. if custom template does not
    # exist, it will fall back to the default behaviour and attempt to load from 'app/views'
    # most of this code is from thew original rails
    def query(path, exts, formats)
      query = File.join(@path, "../../app/themes/#{CONFIG[:theme]}/views", path) # use theme dir instead of default

      exts.each do |ext|
        query << '{' << ext.map {|e| e && ".#{e}" }.join(',') << ',}'
      end

      query.gsub!(/\{\.html,/, "{.html,.text.html,")
      query.gsub!(/\{\.text,/, "{.text,.text.plain,")

      # get results of looking in the theme dirs
      results = Dir[query].reject { |p| File.directory?(p) }.map do |p|
        handler, format = extract_handler_and_format(p, formats)

        contents = File.open(p, "rb") {|io| io.read }

        Template.new(contents, File.expand_path(p), handler,
          :virtual_path => path, :format => format)
      end

      # if we have something from the theme, return that, or fallback to original behaviour
      unless results.nil? || results.empty?
        results
      else
        old_query_for_themes(path, exts, formats)
      end
    end
  end
end
