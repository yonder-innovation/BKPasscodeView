platform :ios, '9.0'

ENV["COCOAPODS_DISABLE_STATS"] = "true"

use_frameworks!
inhibit_all_warnings!

workspace './BKPasscodeViewDemo'

def common_pods
	pod 'AFViewShaker'
end

target "BKPasscodeViewDemo" do
	common_pods
end

target "BKPasscodeViewDemoTests" do
	inherit! :search_paths
  common_pods
end
