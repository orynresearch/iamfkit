const { withPlugins, createRunOncePlugin } = require('@expo/config-plugins');

const pkg = require('./package.json');

/**
 * Expo Config Plugin for iamfkit-react-native.
 * Allows seamless integration with Expo Prebuild / Development Builds without manual pod installs.
 */
function withIamfKit(config) {
  return config;
}

module.exports = createRunOncePlugin(withIamfKit, pkg.name, pkg.version);
