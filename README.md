# Weather Ark - OpenWeather API Integration

> **[Full documentation](https://app.outlayer.ai/docs/examples#weather-ark)** on the OutLayer dashboard.

WASI component that fetches real-time weather data from OpenWeather API.

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

#### Step 1: Publish the WASM

```bash
outlayer upload target/wasm32-wasip2/release/weather-example.wasm
# prints SHA256 and: FastFS URL: https://test.fastfs.io/your.testnet/outlayer.testnet/<sha256>.wasm
outlayer deploy weather-example <FastFS URL>
```

#### Step 2: Store API Key as Encrypted Secret

```bash
outlayer secrets set '{"OPENWEATHER_API_KEY":"your_key_here"}' \
  --project your.testnet/weather-example --profile weather-production
```

Or in the dashboard (Secrets page): project `your.testnet/weather-example`, profile
`weather-production`, secrets JSON `{"OPENWEATHER_API_KEY":"your_key_here"}`, access AllowAll
(or custom conditions).

#### Step 3: Request Execution

```bash
near call outlayer.testnet request_execution '{
  "source": {
    "Project": { "project_id": "your.testnet/weather-example", "version_key": null }
  },
  "secrets_ref": {
    "profile": "weather-production",
    "account_id": "your.testnet"
  },
  "resource_limits": {
    "max_instructions": 50000000000,
    "max_memory_mb": 128,
    "max_execution_seconds": 30
  },
  "response_format": "Json",
  "input_data": "{\"city\":\"Paris\",\"units\":\"metric\"}"
}' --accountId your.testnet --deposit 0.1
```

**Try different cities** by changing `input_data`: `{"city":"Tokyo","units":"metric"}`,
`{"city":"New York","units":"imperial"}` (Fahrenheit), `{"city":"Paris"}`.

#### Step 4: Check Result

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
│   1. Fetch WASM, check sha256│
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
