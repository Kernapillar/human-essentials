module UserInviteService
  # @param name [String]
  # @param email [String]
  # @param roles [Array<Symbol>]
  # @param resource [ApplicationRecord]
  # @return [User]
  def self.invite(email:, resource:, name: nil, roles: [])
    raise "Resource not found!" if resource.nil?

    if !valid_email_format?(email)
      user = { email: email, name: name, errors: "is not a valid email format"}
      return user
    end 

    user = User.find_by(email: email)
    if user
      user.invite!
      add_roles(user, resource: resource, roles: roles)
      return user
    end

    User.invite!(email: email) do |user1|
      user1.name = name if name # Does this get persisted somewhere up the line? - CLF 20230203
      add_roles(user1, resource: resource, roles: roles)
    end
  end

  def self.add_roles(user, resource:, roles: [])
    roles.each do |role|
      user.add_role(role, resource)
    end
  end

  def self.valid_email_format?(email)
    email_regex_pattern = /\A\w{2,}@[a-z]+(\.[a-z]{2,})+\z/i
    email.match(email_regex_pattern)
  end
end
