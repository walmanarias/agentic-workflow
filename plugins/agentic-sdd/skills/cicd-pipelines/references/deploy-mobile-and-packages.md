# Deploy: Mobile & Packages

## React Native (EAS / Fastlane)
```yaml
- uses: actions/checkout@v4
- uses: actions/setup-node@v4
  with: { node-version: 20, cache: npm }
- run: npm ci
- run: npx eas-cli build --platform all --non-interactive --no-wait
  env: { EXPO_TOKEN: ${{ secrets.EXPO_TOKEN }} }
- run: npx eas-cli submit --platform all --non-interactive          # TestFlight / Play (prod job, after approval)
  env: { EXPO_TOKEN: ${{ secrets.EXPO_TOKEN }} }
```
- Bare RN: Fastlane lanes (`fastlane beta`/`release`) with App Store Connect API key + Play service-account JSON in secrets.
- Staging = internal/TestFlight track; production = store release after approval.

## npm
```yaml
- uses: actions/setup-node@v4
  with: { node-version: 20, registry-url: "https://registry.npmjs.org" }
- run: npm ci
- run: npm publish --provenance --access public
  env: { NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }} }
```
- `--provenance` requires `permissions: { id-token: write }`. Trigger on GitHub Release.

## NuGet
```yaml
- uses: actions/setup-dotnet@v4
  with: { dotnet-version: 9.0.x }
- run: dotnet pack -c Release -o out
- run: dotnet nuget push "out/*.nupkg" --api-key "$NUGET_API_KEY" --source https://api.nuget.org/v3/index.json
  env: { NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }} }
```
- **Rollback:** deprecate/unlist the bad version and publish a fixed one (registries are immutable).
