notify { "site.pp":}

include 'srv_elexis'
include 'srv_elexis::jobs'
include 'srv_elexis::wiki'
include 'srv_elexis::vnc_client'
