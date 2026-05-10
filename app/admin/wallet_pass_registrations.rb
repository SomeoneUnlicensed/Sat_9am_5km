# frozen_string_literal: true

ActiveAdmin.register WalletPassRegistration do
  menu false

  actions :index, :show, :destroy

  index do
    selectable_column
    id_column
    column :athlete
    column :device_library_identifier
    column :serial_number
    column :created_at
    actions
  end

  filter :athlete
  filter :serial_number
  filter :created_at

  show do
    attributes_table do
      row :athlete
      row :device_library_identifier
      row :push_token
      row :serial_number
      row :pass_type_identifier
      row :auth_token
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
