class AsciicastDecorator < ApplicationDecorator
  decorates_association :user

  THUMBNAIL_WIDTH = 20
  THUMBNAIL_HEIGHT = 10

  def os
    if user_agent.present?
      os_from_user_agent
    elsif uname.present?
      os_from_uname
    else
      'unknown'
    end
  end

  def terminal_type
    model.terminal_type.presence || '?'
  end

  def shell
    File.basename(model.shell.to_s)
  end

  def title
    if model.title.present?
      model.title
    elsif command.present?
      "$ #{command}"
    else
      "##{id}"
    end
  end

  def thumbnail(width = THUMBNAIL_WIDTH, height = THUMBNAIL_HEIGHT)
    snapshot = Snapshot.build(model.snapshot || [[]] * height)
    thumbnail = SnapshotDecorator.new(snapshot.thumbnail(width, height))
    h.render 'asciicasts/thumbnail', :thumbnail => thumbnail
  end

  def description
    if model.description.present?
      text = model.description.to_s
      markdown(text)
    else
      h.content_tag :em, 'No description.'
    end
  end

  def author_link
    if user
      user.link
    else
      author
    end
  end

  def author_img_link
    if user
      user.img_link
    else
      h.avatar_image_tag nil
    end
  end

  def other_by_user
    if user
      AsciicastDecorator.decorate_collection(
        user.asciicasts.where('id <> ?', model.id).limit(3)
      )
    else
      []
    end
  end

  def author
    if user
      user.nickname
    elsif model.username
      model.username
    else
      'anonymous'
    end
  end

  def embed_script
    src = h.asciicast_url(model, :format => :js)
    id = "asciicast-#{model.id}"
    %(<script type="text/javascript" src="#{src}" id="#{id}" async></script>)
  end

  def formatted_duration
    duration = model.duration.to_i
    minutes = duration / 60
    seconds = duration % 60

    "%02d:%02d" % [minutes, seconds]
  end

  private

  def os_from_user_agent
    match = user_agent.match(/^[^\s]+\s+\(([^\)]+)\)/)
    os = match[1].split(/(\s|-)/).first

    guess_os(os)
  end

  def os_from_uname
    guess_os(uname)
  end

  def guess_os(text)
    if text =~ /Linux/
      'Linux'
    elsif text =~ /Darwin/
      'OSX'
    else
      text.split(' ', 2)[0]
    end
  end

end
