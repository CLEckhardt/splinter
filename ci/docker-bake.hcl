# Copyright 2018-2022 Cargill Incorporated
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

group "default" {
    targets = [
    "scabbard-cli",
    "splinter-cli",
    "splinterd",
    "gameroomd",
    "gameroom-app-acme",
    "gameroom-app-bubba",
    "gameroom-app",
    "gameroom-database"
    ]
}

# --== variables ==--

variable "CARGO_ARGS" {
    default = ""
}

variable "DISTRO" {
    default = "focal"
}

variable "ISOLATION_ID" {
    default = "latest"
}

variable "REPO_VERSION" {
    default = "0.7.1-dev"
}

target "all" {
    args = {
        CARGO_ARGS = "${CARGO_ARGS}"
        REPO_VERSION = "${REPO_VERSION}"
    }
    platforms = ["linux/amd64", "linux/arm64"]
}

# --== splinter services ==--

target "scabbard-cli" {
    inherits = ["all"]
    dockerfile = "services/scabbard/cli/Dockerfile-installed-${DISTRO}"
    tags = ["ghcr.io/splintercommunity/scabbard-cli:${ISOLATION_ID}"]
}

target "splinter-cli" {
    inherits = ["all"]
    dockerfile = "cli/Dockerfile-installed-${DISTRO}"
    tags = ["ghcr.io/splintercommunity/splinter-cli:${ISOLATION_ID}"]
}

target "splinterd" {
    inherits = ["all"]
    dockerfile = "splinterd/Dockerfile-installed-${DISTRO}"
    tags = ["ghcr.io/splintercommunity/splinterd:${ISOLATION_ID}"]
}

# --== gameroom ==--

target "gameroomd" {
    inherits = ["all"]
    dockerfile = "examples/gameroom/daemon/Dockerfile-installed-${DISTRO}"
    tags = ["ghcr.io/splintercommunity/gameroomd:${ISOLATION_ID}"]
}

target "gameroom-app-acme" {
    inherits = ["all"]
    args = {VUE_APP_BRAND = "acme"}
    dockerfile = "examples/gameroom/gameroom-app/Dockerfile-installed"
    tags = ["ghcr.io/splintercommunity/gameroom-app-acme:${ISOLATION_ID}"]
}

target "gameroom-app-bubba" {
    inherits = ["all"]
    args = {VUE_APP_BRAND = "bubba"}
    dockerfile = "examples/gameroom/gameroom-app/Dockerfile-installed"
    tags = ["ghcr.io/splintercommunity/gameroom-app-bubba:${ISOLATION_ID}"]
}

target "gameroom-app" {
    inherits = ["all"]
    args = {VUE_APP_BRAND = "generic"}
    dockerfile = "examples/gameroom/gameroom-app/Dockerfile-installed"
    tags = ["ghcr.io/splintercommunity/gameroom-app:${ISOLATION_ID}"]
}

target "gameroom-database" {
    inherits = ["all"]
    dockerfile = "examples/gameroom/database/Dockerfile-installed"
    tags = ["ghcr.io/splintercommunity/gameroom-database:${ISOLATION_ID}"]
}
