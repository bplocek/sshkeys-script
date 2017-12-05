# Takes as input a CSV file containing: hostname,ssh user, ssh pass
# Generates a keypair locally for each hostname
# Then establishes an ssh connection to each, pushing their key pair and appending
# the string containing all public keys to the remote authorized_keys file
require 'rubygems'
require 'net/ssh'
require 'net/scp'
require 'optparse'
require 'sshkey'
require 'csv'
opts = OptionParser.new
opts.on("-f HOST FILE", "--file FILE", String, "Filename Listing Hosts") { |v| @infile = v }

begin
  opts.parse!(ARGV)
rescue OptionParser::ParseError => e
  puts e
end
raise OptionParser::MissingArgument, "Filename of Hosts [-f]" if @infile.nil?

# Used simple datastructures to avoid overcomplicating
keys = Hash.new
password = Hash.new
users = Hash.new

# Generates a 4k RSA key as well as populating the user and password hashes
CSV.foreach(@infile) do |row|
  keys[row[0]] = SSHKey.generate(
    type: "RSA",
    bits: 4096,
    comment: "#{row[0]} Generated Key - RSA 4096"
  )
  users[row[0]] = row[1]
  password[row[0]] = row[2]
end
# Here's where we create the new string and append each public key to it
auth_keys = String.new
keys.each do |key,sshkey|
    auth_keys << "#{sshkey.ssh_public_key}\n"
end

# 3 remote writes, populating: id_rsa, id_rsa.pub, and appending to authorized_keys
keys.each do |key,sshkey|
  Net::SSH.start(key,users[key],:password => "#{password[key]}") do |ssh|
    ssh.exec!("echo \"#{sshkey.private_key}\">~/.ssh/id_rsa")
    ssh.exec!("echo \"#{sshkey.ssh_public_key}\">~/.ssh/id_rsa.pub")
    ssh.exec!("echo \"#{auth_keys}\">>~/.ssh/authorized_keys")
  end
end