require 'sqlite3'
require 'find'
require 'digest'
require 'ftools'

class FileDB
  attr_accessor :copy_count, :delete_count
  def initialize(type)
    @type = type
    @master_root_path = '/Volumes/home'
    @copy_count = 0
    @delete_count = 0
  end
  def bootstrap
    # create empty db
    @db = SQLite3::Database.new "./fileInfoDb#{@type}"
    @db.execute "CREATE TABLE IF NOT EXISTS files(MD5 TEXT, Computer TEXT, Path TEXT, Type TEXT)"
  end
  def open_db
    @db = SQLite3::Database.open "./fileInfoDb#{@type}" if !@db
    @insert = @db.prepare('INSERT INTO files VALUES(?, ?, ?, ?)')
    @lookup = @db.prepare('SELECT count(*) FROM files WHERE Path=?')
    @lookupMasterMD5 = @db.prepare('SELECT count(*) FROM files WHERE MD5=?')
  end

  def close
    @insert.close if @insert
    @lookup.close if @lookup
    @lookupMasterMD5.close if @lookupMasterMD5
    @db.close if @db
  end

  def copy_file(source, destination)
    p "will copy file to #{destination} \n"
    File.makedirs(File.dirname(destination))
    File.copy(source, destination)
    @copy_count += 1
  end

  def delete_local_file(source)
    p "will delete local file #{source}"
    File.safe_unlink(source)
    @delete_count += 1
  end

  def add_file(file_path)
    # For the master, check if file has already been added
    if @computer == 'master' then
      result_set = @lookup.execute(file_path)
      if result_set.next[0] == 0 then
        md5 = Digest::MD5.file(file_path).hexdigest
        @insert.execute( md5, @computer, file_path, @type.gsub('.','') )
        puts "Added #{file_path}"
      else
        puts "File already added #{file_path}"
      end
    else
      # not the master, so add the file only if MD5 is not already in master
      md5 = Digest::MD5.file(file_path).hexdigest
      p md5
      result_set = @lookupMasterMD5.execute(md5)
      if result_set.next[0] == 0 then
        dest_path = file_path.gsub(@root_path,@master_root_path+'/From '+@computer)
        copy_file(file_path, dest_path)
        # TODO : add file to info db
        @insert.execute( md5, @computer, dest_path, @type.gsub('.','') )
      end
      delete_local_file(file_path)
    end
  end

  def create_master_info
    # scan files on master computer and store info into db
    @computer = 'master'
    Find.find(@master_root_path) do |file_path|
      next if File.extname(file_path).downcase != @type.downcase
      add_file(file_path) if !File.directory?(file_path)
    end
  end

  def process_local(computer, root_path)
    @computer = computer
    @root_path = root_path
    Find.find(@root_path) do |file_path|
      next if File.extname(file_path).downcase != @type.downcase
      add_file(file_path) if !File.directory?(file_path)
    end
  end
end
