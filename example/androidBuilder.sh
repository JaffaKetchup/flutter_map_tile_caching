#!/bin/bash

flutter clean | more
flutter build apk --split-per-abi --obfuscate --split-debug-info=/symbols 