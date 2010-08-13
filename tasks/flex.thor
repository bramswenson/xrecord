class FlexProj < Thor
  PROJECT_NAME = 'XRecordWidget'
  #map "-L" => :list

  desc "build", "builds #{PROJECT_NAME} project"
  def build
    validate_source_file
    puts "preparing to compile with command:"
    puts compile_command
    puts `#{compile_command}`
  end

  desc "debug_build", "builds #{PROJECT_NAME} project with debugging enabled"
  def debug_build
    validate_source_file
    puts "preparing to compile with command:"
    puts compile_command( true )
    puts `#{compile_command( true )}`
  end

  #desc "list [SEARCH]", "list all of the available apps, limited by SEARCH"
  #def list(search="")
  #  # list everything
  #end
  
  private
  def compile_command( debug=false )
    "#{mxmlc} --debug=#{debug} -output #{object_file_path} #{source_file_path}"
  end

  def object_file_path
    File.join( project_root, 'public', 'objects', "#{PROJECT_NAME}.swf")
  end

  def validate_source_file
    raise ArgumentError.new("source file not found: #{source_file_path}" ) unless 
      File.exists?( source_file_path )
  end

  def source_file_path
    File.join( project_root, 'src', "#{PROJECT_NAME}.mxml" )
  end

  def project_root
    File.expand_path( File.dirname( File.dirname( __FILE__ ) ) )
  end

  def mxmlc
    begin
      File.expand_path(`which mxmlc`).chomp
    rescue 
      raise ArgumentError.new('mxmlc not found')
    end
  end

end
