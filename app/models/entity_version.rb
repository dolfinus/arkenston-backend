class EntityVersion < PaperTrail::Version
  belongs_to :author, class_name: 'User',
                      foreign_key: "whodunnit",
                      optional: true
end
