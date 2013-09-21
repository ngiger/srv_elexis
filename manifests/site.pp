notify { "site.pp":}

include 'elexis-jenkins'
include 'elexis-jenkins::jobs'
