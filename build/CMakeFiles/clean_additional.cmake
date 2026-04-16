# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/appApplication_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/appApplication_autogen.dir/ParseCache.txt"
  "appApplication_autogen"
  )
endif()
