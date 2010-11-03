include YARD::Templates::Helpers::HtmlHelper

def init
  super
  asset("js/cucumber.js",file("js/cucumber.js",true))

  @features = Registry.all(:feature)

  if @features
    @features.each {|feature| serialize(feature) } 
    generate_full_list(@features)
  end
  
  @tags = Registry.all(:tag)

  if @tags
    @tags.each {|tag| serialize(tag) }
    generate_full_list @tags.sort {|x,y| y.all_scenarios.size <=> x.all_scenarios.size }
  end

  @steps = Registry.all(:step)
  generate_full_list(@steps) if @steps

  Templates::Engine.with_serializer(YARD::CodeObjects::Cucumber::CUCUMBER_STEPTRANSFORM_NAMESPACE, options[:serializer]) do
    options[:object] = YARD::CodeObjects::Cucumber::CUCUMBER_STEPTRANSFORM_NAMESPACE
    T('layout').run(options)
  end

  feature_directories = YARD::CodeObjects::Cucumber::CUCUMBER_NAMESPACE.children.find_all {|child| child.is_a?(YARD::CodeObjects::Cucumber::FeatureDirectory) }

  serialize(YARD::CodeObjects::Cucumber::CUCUMBER_NAMESPACE)
  serialize_feature_directories(feature_directories)

  serialize(YARD::CodeObjects::Cucumber::CUCUMBER_TAG_NAMESPACE)
end


def generate_full_list(objects,friendly_name=nil)
  if !objects.empty?
    @items = objects
    @list_type = "#{objects.first.type.to_s}s"
    @list_title = "#{friendly_name || objects.first.type.to_s.capitalize} List"
    @list_class = "class"
    asset("#{objects.first.type}_list.html",erb(:full_list))
  else
    log.warn "Full List: Failed to create a list because the objects array is empty."
  end
end

#
# Remove CUCUMBER namespace from the class list
#
def class_list(root = Registry.root)
  root.instance_eval { children.delete YARD::CodeObjects::Cucumber::CUCUMBER_NAMESPACE } if root == Registry.root
  out = super(root)
  root.instance_eval { children << YARD::CodeObjects::Cucumber::CUCUMBER_NAMESPACE } if root == Registry.root
  out
end

def serialize_feature_directories(namespaces)
  namespaces.each do |namespace|
    Templates::Engine.with_serializer(namespace, options[:serializer]) do
      options[:object] = namespace
      T('layout').run(options)
    end
    serialize_feature_directories(namespace.children.find_all {|child| child.is_a?(YARD::CodeObjects::Cucumber::FeatureDirectory)})
  end
end