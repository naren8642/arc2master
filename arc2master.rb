require 'rubygems'
require './arc_worker'


begin

  puts Time.now

  fdb = FileDB.new('.jpg')
  #fdb.bootstrap
  fdb.open_db

  #fdb.create_master_info

  fdb.process_local('iMac', './test')

rescue SQLite3::Exception => e

  puts 'Exception occurred'
  puts e

ensure
  print "Copy count = #{fdb.copy_count} and Delete count = #{fdb.delete_count}\n"
  fdb.close if fdb
  puts Time.now
end
