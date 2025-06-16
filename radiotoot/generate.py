from mastodon import Mastodon

# Replace with your Mastodon instance URL
api_base_url = 'https://chatwithus.live'

# Create app and get the client credentials
Mastodon.create_app(
    'my_app',
    api_base_url = api_base_url,
    to_file = 'clientcred.secret'
)

print("Client credentials saved to 'clientcred.secret'")
