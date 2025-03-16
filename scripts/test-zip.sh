PWD=/Users/adrianibanez/Documents/projects/2024_sensor-platform/checkouts/elixir-desktop-ios-example-app
#$(pwd)

cd elixir-app/_build/ios_prod/rel/default_release/
ls -lah 
ARCHIVE="$PWD/test.zip"
zip -9r "$ARCHIVE" lib/ releases/ --exclude "*.so"
zip -g $ARCHIVE `find . -name "libbtleplug_*.so" | head -1` || true

cd $PWD

zip -l $ARCHIVE