class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML

  attr_reader :template
  alias_method :h, :template

  def initialize(template, options = {})
    @template = template
    @project = @template.instance_variable_get("@project")
    @options = options.dup
    super options
  end

  # If project has issue number 39, apostrophe will be linked in
  # regular text to the issue as Redcarpet will convert apostrophe to
  # #39;
  # We replace apostrophe with right single quote before Redcarpet
  # does the processing and put the apostrophe back in postprocessing.
  # This only influences regular text, code blocks are untouched.
  def normal_text(text)
    return text unless text.present?
    text.gsub("'", "&rsquo;")
  end

  def block_code(code, language)
    # New lines are placed to fix an rendering issue
    # with code wrapped inside <h1> tag for next case:
    #
    # # Title kinda h1
    #
    #     ruby code here
    #
    <<-HTML

<div class="highlighted-data #{h.user_color_scheme_class}">
  <div class="highlight">
    <pre><code class="#{language}">#{h.send(:html_escape, code)}</code></pre>
  </div>
</div>

    HTML
  end

  def link(link, title, content)
    h.link_to_gfm(content, link, title: title)
  end

  def header(text, level)
    if @options[:no_header_anchors]
      "<h#{level}>#{text}</h#{level}>"
    else
      id = ActionController::Base.helpers.strip_tags(h.gfm(text)).downcase() \
          .gsub(/[^a-z0-9_-]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
      "<h#{level} id=\"#{id}\">#{text}<a href=\"\##{id}\"></a></h#{level}>"
    end
  end

  def postprocess(full_document)
    full_document.gsub!("&rsquo;", "'")
    unless @template.instance_variable_get("@project_wiki") || @project.nil?
      full_document = h.create_relative_links(full_document)
    end
    if @options[:parse_tasks]
      h.gfm_with_tasks(full_document)
    else
      h.gfm(full_document)
    end
  end
end
