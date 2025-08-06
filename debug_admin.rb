user = User.find_by(email: 'admin@financetracker.com')
if user
  puts 'Admin user found:'
  puts "  ID: #{user.id}"
  puts "  Email: #{user.email}"
  puts "  Admin: #{user.admin?}"
  puts "  Encrypted password present: #{user.encrypted_password.present?}"
  puts "  Password valid: #{user.valid_password?('AdminPass123!')}"
else
  puts 'Admin user not found!'
end
