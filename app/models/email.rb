class Email < ActiveRecord::Base
  belongs_to :from, foreign_key: "from_id", class_name: :User
  has_many :receives

  after_create :initialization

  HASH_LENGTH = 12


  def bad?
    bad = false
    bad = true if self.body.blank?
    bad = true if self.body.length < 100
    bad = true if self.body.split.length < 20
    bad = true if self.from.banned

    return bad
  end

  def reply_hash
    self.body.lstrip[1...HASH_LENGTH+1]
  end

  def was_sent
    self.sent = self.sent + 1
    save
  end

  private

  def initialization
    self.key = Digest::SHA1.hexdigest(self.id.to_s)[0...HASH_LENGTH]

    compose

    save
  end

  def compose
    @markdown ||= Redcarpet::Markdown.new Redcarpet::Render::HTML

    self.body = ActionView::Base.full_sanitizer.sanitize self.body
    self.body = @markdown.render self.body

    unless self.no_reply
      self.body = "<p id='hash'>##{self.key}</p><br/>" << self.body
    end
  end
end
