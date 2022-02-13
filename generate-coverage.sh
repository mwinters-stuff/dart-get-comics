#!/bin/bash
dart run test --coverage=./coverage
genhtml coverage/lcov.info -o coverage/