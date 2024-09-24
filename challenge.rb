require 'json'

# Load and parse JSON data from the given file
def load_json(filename)
  file = File.read(filename)
  JSON.parse(file)
rescue StandardError => e
  # Handle file read or parse errors
  puts "Error loading #{filename}: #{e.message}"
  []
end

# Process the users and companies to generate the required output
def process_data(users, companies)
  output = []

  # Sort companies by their id
  companies.sort_by! { |company| company['id'] }

  companies.each do |company|
    output << "Company Id: #{company['id']}"
    output << "Company Name: #{company['name']}"

    emailed_users = []
    not_emailed_users = []
    total_top_up = 0

    # Select active users belonging to this company
    company_users = users.select { |user| user['company_id'] == company['id'] && user['active_status'] }

    # Sort company users by last name
    company_users.sort_by! { |user| user['last_name'] }

    # Process each user and calculate new token balances
    company_users.each do |user|
      new_token_balance = user['tokens'] + company['top_up']
      total_top_up += company['top_up']

      # Prepare the user details string
      user_output = <<~USER_DETAILS
        \t#{user['last_name']}, #{user['first_name']}, #{user['email']}
        \t  Previous Token Balance, #{user['tokens']}
        \t  New Token Balance, #{new_token_balance}
      USER_DETAILS

      # Sort users into emailed or not emailed based on email status
      if user['email_status'] && company['email_status']
        emailed_users << user_output
      else
        not_emailed_users << user_output
      end
    end

    # Add emailed users to output if present
    output << "\tUsers Emailed:"
    output.concat(emailed_users) if emailed_users.any?

    # Add not emailed users to output if present
    output << "\tUsers Not Emailed:"
    output.concat(not_emailed_users) if not_emailed_users.any?

    # Include total top-up information
    output << "\tTotal amount of top ups for #{company['name']}: #{total_top_up}"
    output << "" # Add a blank line for separation
  end

  output
end

# Main function to generate the output file
def generate_output_file
  users = load_json('users.json')
  companies = load_json('companies.json')

  # If either file failed to load, exit early
  return if users.empty? || companies.empty?

  output = process_data(users, companies)

  # Write output to file
  File.open('output.txt', 'w') do |file|
    output.each { |line| file.puts(line) }
  end
  puts "Output written to output.txt"
end

# Execute the main function
generate_output_file
