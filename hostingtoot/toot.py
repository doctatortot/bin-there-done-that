from mastodon import Mastodon

# Replace with your Mastodon instance URL and your login credentials
api_base_url = 'https://doctator@chatwithus.live'
client_cred_file = 'clientcred.secret'
user_cred_file = 'usercred.secret'
email = 'your_email@example.com'
password = 'your_password'

# Create app and get the client credentials
Mastodon.create_app(
    'my_app',
    api_base_url = api_base_url,
    to_file = client_cred_file
)

# Log in and get the user credentials
mastodon = Mastodon(
    client_id = client_cred_file,
    api_base_url = api_base_url
)
mastodon.log_in(
    email,
    password,
    to_file = user_cred_file
)

print("Access token generated and saved to 'usercred.secret'")
