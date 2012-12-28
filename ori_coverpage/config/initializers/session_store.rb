# Be sure to restart your server when you modify this file.

Coverpage::Application.config.session_store :cookie_store, :key => '_milkfarm_session',
            :secret      => '3deaef961fce0lkad93134lkjad0f9i134lkjadf14hnang857'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
Coverpage::Application.config.session_store :active_record_store
