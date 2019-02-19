# frozen_string_literal: true

# Cloud Foundry MapR Buildpack
# Copyright (c) 2019 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'mapr_buildpack'
require 'mapr_buildpack/buildpack_version'
require 'mapr_buildpack/mapr_client'
require 'fileutils'
require 'open-uri'
require 'open3'
require 'yaml'
require 'mapr_buildpack/configuration'

module MapRBuildpack
  # Encapsulates the supply functionality for applications using MapR
  class Buildpack

    # Creates a new instance.
    # @param [String] app_dir The application directory
    def initialize(app_dir, deps, index)
      @app_dir = app_dir
      @deps = deps
      @index = index
    end

    # Supplies the MapR client to the droplet
    #
    # @return [void]
    def supply
      print "Supplying MapR client\n"

      configuration = MapRBuildpack::Configuration.new

      mapr_client_version = configuration.version
      url = configuration.url(mapr_client_version)
      
      print "Selected MapR client version #{mapr_client_version}\n"

      filename = URI(url).path.split('/').last
      download_target = File.join(@app_dir, filename)
      target_path = File.join(@app_dir, ".mapr")

      mapr_client = MapRBuildpack::MapRClient.new
      mapr_client.download(mapr_client_version, url, download_target)
      mapr_client.unzip(download_target, target_path)

      # Create config.yml to provide environment variables
      buildpackConfig = {
        "name" => "mapr_buildpack",
        "config" => {
          "environment_variables" => {
            "MAPR_HOME" => "/home/vcap/app/.mapr/mapr",
            "MAPR_TICKETFILE_LOCATION" => "/home/vcap/app/.mapr-ticket/ticket"
          }
        }
      }
      config_path = File.join(@deps, @index, "config.yml")
      File.open(config_path, "w") { |file| file.write(buildpackConfig.to_yaml) }

      print "Supplied MapR client at #{target_path}\n"
    end
  end
end