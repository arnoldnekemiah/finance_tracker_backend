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

# Create sample categories for demo purposes
default_categories = [
  { name: 'Food & Dining', color: '#FF6B6B' },
  { name: 'Transportation', color: '#4ECDC4' },
  { name: 'Shopping', color: '#45B7D1' },
  { name: 'Entertainment', color: '#96CEB4' },
  { name: 'Bills & Utilities', color: '#FFEAA7' },
  { name: 'Healthcare', color: '#DDA0DD' },
  { name: 'Income', color: '#98D8C8' },
  { name: 'Savings', color: '#F7DC6F' }
]

default_categories.each do |category_attrs|
  Category.find_or_create_by(name: category_attrs[:name]) do |category|
    category.color = category_attrs[:color]
    category.user_id = User.first&.id # Assign to first user if exists
  end
end

puts "✅ Default categories created"
puts "🚀 Seeding completed successfully!"
