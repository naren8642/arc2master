# arc2master
Archive local files to master backup

Archives files in 2 steps.

1. Create MD5 sums for all files of specified type on the master backup location. These are stored in a SQLite db
2. The backup step - looks at all files needing to backed up, only copies files if a file with the same MD5 sum does not already exist on the master.

arc_master.rb has the main code, arc2master.rb calls it with the right parameters.

