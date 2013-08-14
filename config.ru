require './roughdraft'

# Gzip responses
use Rack::Deflater

# Run the application
run RoughdraftApp