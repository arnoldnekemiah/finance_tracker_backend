# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default admin user
default_admin_email = 'admin@financetracker.com'
default_admin_password = 'AdminPass123!'

if User.find_by(email: default_admin_email).nil?
  admin_user = User.create!(
    email: default_admin_email,
    password: default_admin_password,
    password_confirmation: default_admin_password,
    first_name: 'Admin',
    last_name: 'User',
    currency: 'USD',
    admin: true
  )
  
  puts "✅ Default admin user created:"
  puts "   Email: #{admin_user.email}"
  puts "   Password: #{default_admin_password}"
  puts "   Please change the password after first login!"
else
  puts "ℹ️  Admin user already exists with email: #{default_admin_email}"
end

# Default categories are now created for each user upon registration.
# See User model and DefaultCategoryCreatorService.

puts "🚀 Seeding completed successfully!"
