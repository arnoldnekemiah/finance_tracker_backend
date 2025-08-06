user = User.find_by(email: 'admin@financetracker.com')
if user
  user.password = 'AdminPass123!'
  user.password_confirmation = 'AdminPass123!'
  if user.save
    puts 'Admin password reset successfully!'
    puts "Email: #{user.email}"
    puts "Password: AdminPass123!"
    puts "Admin: #{user.admin?}"
    puts "Password valid now: #{user.valid_password?('AdminPass123!')}"
  else
    puts 'Failed to reset password:'
    puts user.errors.full_messages
  end
else
  puts 'Admin user not found!'
end
