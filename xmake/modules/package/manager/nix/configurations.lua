--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      ZZBaron
-- @file        configurations.lua
--

-- get configurations
--
-- Source priority order (highest to lowest):
--   1. nix-shell / nix develop / stdenv.mkDerivation
--   2. home-manager profile                         
--   3. nix profile / nix-env (~/.nix-profile)       
--   4. NixOS system profile (/run/current-system/sw)
--
-- Usage:
--   add_requires("nix::zlib", {configs = {use_nix_profile = true}})
-- 
function main()
    return {
        use_nix_shell    = {description = "Search packages from the active nix-shell / nix develop / stdenv.mkDerivation environment. Default: true.",  default = true},
        use_homemanager  = {description = "Search packages installed via home-manager (/etc/profiles/per-user/$USER). Default: false.",                 default = false},
        use_nix_profile  = {description = "Search packages installed via nix profile or nix-env (~/.nix-profile). Default: false.",                     default = false},
        use_nixos_system = {description = "Search packages from the NixOS system profile (/run/current-system/sw). Default: false.",                    default = false},
    }
end