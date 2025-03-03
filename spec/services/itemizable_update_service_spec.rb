RSpec.describe ItemizableUpdateService do
  let(:storage_location) { create(:storage_location, organization: @organization, item_count: 0) }
  let(:new_storage_location) { create(:storage_location, organization: @organization, item_count: 0) }
  let(:item1) { create(:item, organization: @organization) }
  let(:item2) { create(:item, organization: @organization) }
  let!(:ii1) { create(:inventory_item, storage_location: storage_location, item: item1, quantity: 10) }
  let!(:ii2) { create(:inventory_item, storage_location: new_storage_location, item: item2, quantity: 10) }
  let!(:ii3) { create(:inventory_item, storage_location: storage_location, item: item2, quantity: 10) }
  let!(:ii4) { create(:inventory_item, storage_location: new_storage_location, item: item1, quantity: 10) }

  around(:each) do |ex|
    freeze_time do
      ex.run
    end
  end

  describe "increases" do
    let(:itemizable) do
      line_items = [
        create(:line_item, item_id: item1.id, quantity: 5),
        create(:line_item, item_id: item2.id, quantity: 5)
      ]
      create(:donation,
        organization: @organization,
        storage_location: storage_location,
        line_items: line_items,
        issued_at: 1.day.ago)
    end

    let(:attributes) do
      {
        issued_at: 2.days.ago,
        line_items_attributes: {"0": {item_id: item1.id, quantity: 2}, "1": {item_id: item2.id, quantity: 2}}
      }
    end

    subject do
      described_class.call(itemizable: itemizable, params: attributes, type: :increase)
    end

    it "should update quantity in same storage location" do
      expect(storage_location.size).to eq(20)
      expect(new_storage_location.size).to eq(20)
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(14)
      expect(new_storage_location.size).to eq(20)
      expect(itemizable.issued_at).to eq(2.days.ago)
    end

    it "should update quantity in different locations" do
      attributes[:storage_location_id] = new_storage_location.id
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(10)
      expect(new_storage_location.size).to eq(24)
    end
  end

  describe "decreases" do
    let(:itemizable) do
      line_items = [
        create(:line_item, item_id: item1.id, quantity: 5),
        create(:line_item, item_id: item2.id, quantity: 5)
      ]
      create(:distribution,
        organization: @organization,
        storage_location: storage_location,
        line_items: line_items,
        issued_at: 1.day.ago)
    end

    let(:attributes) do
      {
        issued_at: 2.days.ago,
        line_items_attributes: {"0": {item_id: item1.id, quantity: 2}, "1": {item_id: item2.id, quantity: 2}}
      }
    end

    subject do
      described_class.call(itemizable: itemizable, params: attributes, type: :decrease)
    end

    it "should update quantity in same storage location" do
      expect(storage_location.size).to eq(20)
      expect(new_storage_location.size).to eq(20)
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(26)
      expect(new_storage_location.size).to eq(20)
      expect(itemizable.issued_at).to eq(2.days.ago)
    end

    it "should update quantity in different locations" do
      attributes[:storage_location_id] = new_storage_location.id
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(30)
      expect(new_storage_location.size).to eq(16)
    end

    it "should delete empty inventory items" do
      attributes[:storage_location_id] = new_storage_location.id
      attributes[:line_items_attributes] =
        {"0": {item_id: item1.id, quantity: 10}, "1": {item_id: item2.id, quantity: 10}}

      subject

      expect(new_storage_location.size).to eq(0)
      expect(new_storage_location.inventory_items.count).to eq(0)
    end
  end
end
