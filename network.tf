# This will cause state changes per user, but meh. 
# It is just to test that we can get to lakeFS / etc for debugging any issue.
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
