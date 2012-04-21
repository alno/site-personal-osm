# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

regions = ["RU-ALT", "RU-AMU", "RU-ARK", "RU-AST", "RU-BA", "RU-BEL", "RU-BRY", "RU-BU", "RU-VLA", "RU-VGG", "RU-VLG", "RU-VOR", "RU-DA", "RU-YEV", "RU-SVE", "RU-ZAB", "RU-IVA", "RU-IN", "RU-IRK", "RU-KB", "RU-KGD", "RU-KL", "RU-KLU", "RU-KAM", "RU-KC", "RU-KR", "RU-KEM", "RU-KIR", "RU-KO", "RU-KOS", "RU-KDA", "RU-KYA", "RU-KGN", "RU-KRS", "RU-LIP", "RU-MAG", "RU-ME", "RU-MO", "RU-MOS", "RU-MUR", "RU-NEN", "RU-NIZ", "RU-NGR", "RU-NVS", "RU-OMS", "RU-ORE", "RU-ORL", "RU-PNZ", "RU-PER", "RU-PRI", "RU-PSK", "RU-AL", "RU-ROS", "RU-RYA", "RU-SAM", "RU-SPO", "RU-SAR", "RU-SAK", "RU-SE", "RU-SMO", "RU-STA", "RU-TAM", "RU-TA", "RU-TVE", "RU-TOM", "RU-TY", "RU-TUL", "RU-TYU", "RU-UD", "RU-ULY", "RU-KHA", "RU-KK", "RU-KHM", "RU-CHE", "RU-CE", "RU-CU", "RU-CHU", "RU-SA", "RU-YAN", "RU-YAR"]

every 1.day, :at => '05:00' do

  regions.each do |reg|
    rake "import:zkir URL=http://peirce.gis-lab.info/ADDR_CHK/#{reg}.mp_addr.xml"
  end

end
