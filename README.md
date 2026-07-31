# Weather Ark - OpenWeather API Integration

> **[Full documentation](https://outlayer.fastnear.com/docs/examples#weather-ark)** on the OutLayer dashboard.

WASI component that fetches real-time weather data from OpenWeather API.

> 🚀 **Ready to test on NEAR Testnet!** Pre-configured secrets available at `github.com/out-layer/weather-example` (profile: `default`, owner: `zavodil2.testnet`). Skip to [Quick Start](#quick-start-testnet-with-pre-configured-secrets-) to try it now!

## Features

- ✅ Real-time weather data for any city
- ✅ Support for metric/imperial units
- ✅ API key via encrypted secrets (WASI environment variables)
- ✅ HTTP requests using WASI P2
- ✅ JSON input/output

## Input Format

```json
{
  "city": "London",
  "units": "metric"
}
```

**Fields:**
- `city` (required): City name (e.g., "London", "New York", "Tokyo")
- `units` (optional): "metric" (default) or "imperial"

## Output Format

```json
{
  "city": "London",
  "country": "GB",
  "temperature": 15.5,
  "temperature_unit": "C",
  "description": "overcast clouds",
  "humidity": 72,
  "wind_speed": 3.6
}
```

## Building

```bash
./build.sh
```

The script adds the `wasm32-wasip2` target if it is missing, builds in release mode,
and copies the result to `./weather-example.wasm`.

Equivalent by hand:

```bash
# Add WASI P2 target
rustup target add wasm32-wasip2

# Build
cargo build --target wasm32-wasip2 --release

# Output: target/wasm32-wasip2/release/weather-example.wasm
```

## Getting OpenWeather API Key

**Required**: You must provide an OpenWeather API key to use this module.

1. Get a free API key from: https://openweathermap.org/api
2. Free tier includes:
   - 60 calls/minute
   - 1,000,000 calls/month
   - No credit card required

## Testing Locally

### With wasi-test-runner (Recommended)

```bash
cd ../wasi-test-runner

# Test with your API key
cargo run --release -- \
  --wasm ../weather-example/target/wasm32-wasip2/release/weather-example.wasm \
  --input '{"city":"London"}' \
  --env OPENWEATHER_API_KEY=your_api_key_here
```

### With wasmtime

```bash
echo '{"city":"Tokyo","units":"metric"}' | \
  wasmtime --env OPENWEATHER_API_KEY=your_api_key_here \
  target/wasm32-wasip2/release/weather-example.wasm
```

## Deploying to NEAR OutLayer

### Quick Start (Testnet with Pre-configured Secrets) ✨

**Good news!** We've already set up encrypted secrets on testnet, so you can test immediately:

```bash
# Test weather for any city right now (no setup needed!)
near contract call-function as-transaction outlayer.testnet request_execution json-args '{
    "code_source": {
      "repo": "https://github.com/out-layer/weather-example",
      "commit": "main",
      "build_target": "wasm32-wasip2"
    },
    "secrets_ref": {
      "repo": "github.com/out-layer/weather-example",
      "profile": "default",
      "account_id": "zavodil2.testnet"
    },
    "resource_limits": {
      "max_instructions": 50000000000,
      "max_memory_mb": 128,
      "max_execution_seconds": 30
    },"response_format": "Json",
    "input_data": "{\"city\":\"London\",\"units\":\"metric\"}"
  }' prepaid-gas '100.0 Tgas' attached-deposit '0.1 NEAR' sign-as your-account.testnet network-config testnet sign-with-keychain send
```

Execution result: https://testnet.nearblocks.io/txns/HreK5ResxyQpRznteJLbyPWQvZMbCyuSvuqLnRr2LhtH

**Try different cities:**
```bash
# Tokyo (metric)
--input_data '{"city":"Tokyo","units":"metric"}'

# New York (imperial - Fahrenheit)
--input_data '{"city":"New York","units":"imperial"}'

# Paris
--input_data '{"city":"Paris"}'

# Moscow
--input_data '{"city":"Moscow"}'
```

**Available pre-configured secrets:**
- **Repo**: `github.com/out-layer/weather-example`
- **Profile**: `default`
- **Owner**: `zavodil2.testnet`
- **Contains**: OpenWeather API key (free tier)

---

### Production Deployment (Your Own Secrets)

#### Step 1: Store API Key as Encrypted Secret

```bash
# 1. Go to dashboard
cd ../../dashboard
npm run dev

# 2. Open http://localhost:3000/secrets
# 3. Connect wallet
# 4. Create secret:
#    - Repo: github.com/your-username/your-repo
#    - Branch: main (optional)
#    - Profile: weather-production
#    - Secrets JSON: {"OPENWEATHER_API_KEY":"your_key_here"}
#    - Access: AllowAll (or custom conditions)
```

#### Step 2: Request Execution

```bash
near call outlayer.testnet request_execution '{
  "code_source": {
    "repo": "https://github.com/your-username/your-repo",
    "commit": "main",
    "build_target": "wasm32-wasip2"
  },
  "secrets_ref": {
    "repo": "github.com/your-username/your-repo",
    "profile": "weather-production",
    "account_id": "your.testnet"
  },
  "resource_limits": {
    "max_instructions": 50000000000,
    "max_memory_mb": 128,
    "max_execution_seconds": 30
  },
  "input_data": "{\"city\":\"Paris\",\"units\":\"metric\"}"
}' --accountId your.testnet --deposit 0.1
```

#### Step 3: Check Result

```bash
# Get execution request ID from previous command output
near view outlayer.testnet get_request '{"request_id": 123}'
```

## Example Output

```json
{
  "city": "London",
  "country": "GB",
  "temperature": 15.5,
  "temperature_unit": "C",
  "description": "overcast clouds",
  "humidity": 72,
  "wind_speed": 3.6
}
```

## Architecture

```
┌─────────────────┐
│  NEAR Contract  │
│  (client.near)  │
└────────┬────────┘
         │ request_execution(city="London")
         ↓
┌─────────────────────────────┐
│   OutLayer Contract         │
│   (outlayer.testnet)      │
│   - Stores encrypted secrets│
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│   Worker                    │
│   1. Compile weather-example    │
│   2. Decrypt secrets        │
│   3. Inject OPENWEATHER_*   │
│   4. Execute WASM           │
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│   Weather Ark WASM          │
│   - Read OPENWEATHER_API_KEY│
│   - HTTP GET to OpenWeather │
│   - Parse JSON response     │
│   - Return formatted data   │
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│   OpenWeather API           │
│   api.openweathermap.org    │
└─────────────────────────────┘
```

## Use Cases

1. **Weather Bot**: On-chain smart contract that provides weather data to users
2. **Conditional Payments**: Release funds based on weather conditions (temperature, rain, etc.)
3. **Agricultural Contracts**: Trigger actions based on local weather
4. **Travel Planning**: Check weather before booking

## API Key

**Required**: You must provide an OpenWeather API key via encrypted secrets.

- **Get Key**: https://openweathermap.org/api (free tier available)
- **Free Tier**: 60 calls/minute, 1,000,000 calls/month
- **Storage**: Store via OutLayer encrypted secrets (see Step 1 above)

## Dependencies

- `serde` / `serde_json` - JSON serialization
- `wasi-http-client` - HTTP requests (WASI P2)
- `urlencoding` - Encode city names for URLs

## Notes

- Uses WASI Preview 2 (wasm32-wasip2) for HTTP support
- **API key required**: Must be provided via encrypted secrets
- Output is always < 900 bytes (NEAR limit)
- Timeout: 10 seconds for HTTP request
- Supports all cities in OpenWeather database

## Troubleshooting

**"No weather data found"**:
- Check city spelling
- Try with country code: "London,GB" or "London,UK"

**"Weather API error (401)"**:
- Invalid API key
- Check OPENWEATHER_API_KEY in secrets

**"Weather API error (404)"**:
- City not found in OpenWeather database
- Try alternative spelling or nearby city

## License

MIT
