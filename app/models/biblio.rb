class Biblio
  attr_accessor :id, :title, :author, :items, :record_type, :no_in_queue

  include ActiveModel::Serialization
  include ActiveModel::Validations

  RECORD_TYPES = [
    {code: 'a', label: 'monographic_component', queue_level: 'bib'},
    {code: 'b', label: 'serial_component', queue_level: 'bib'},
    {code: 'c', label: 'collection', queue_level: 'item'},
    {code: 'd', label: 'subunit', queue_level: 'bib'},
    {code: 'i', label: 'integrating_resource', queue_level: 'bib'},
    {code: 'm', label: 'monograph', queue_level: 'bib'},
    {code: 's', label: 'serial', queue_level: 'item'}
  ]

  def can_be_borrowed
    @items.each do |item|
      return true if item.can_be_borrowed
    end
    return false
  end

  def can_be_queued
    @items.each do |item|
      return true if item.can_be_queued
    end

    return false
  end

  def can_be_queued_on_item
    Biblio.queue_level(@record_type) == 'item'
  end

  def self.queue_level record_type
    type_obj = RECORD_TYPES.find do |type|
      type[:label] == record_type
    end

    return type_obj[:queue_level]
  end

  def as_json options = {}
    super.merge(can_be_queued: can_be_queued, can_be_queued_on_item: can_be_queued_on_item)
  end


  def initialize id, bib_xml, reserves_xml
    @id = id
    parse_xml bib_xml, reserves_xml
  end

  def self.find id
    base_url = APP_CONFIG['koha']['base_url']
    user =  APP_CONFIG['koha']['user']
    password =  APP_CONFIG['koha']['password']

    bib_url = "#{base_url}/bib/#{id}?userid=#{user}&password=#{password}&items=1"
    reserves_url = "#{base_url}/reserves/list?biblionumber=#{id}&userid=#{user}&password=#{password}"
    bib_response = RestClient.get bib_url
    reserves_response = RestClient.get reserves_url
    item = self.new id, bib_response, reserves_response
    return item
  end

  def self.find_by_id id
    self.find id
  rescue => error
    return nil
  end

  def parse_xml bib_xml, reserves_xml
    bib_xml = Nokogiri::XML(bib_xml).remove_namespaces!
    reserves_xml = Nokogiri::XML(reserves_xml).remove_namespaces!

    @items = []

    @author = bib_xml.search('//record/datafield[@tag="100"]/subfield[@code="a"]').text

    @record_type = Biblio.parse_record_type(xml.search('//record/leader').text)

    if bib_xml.search('//record/datafield[@tag="245"]/subfield[@code="a"]').text.present?
      @title = bib_xml.search('//record/datafield[@tag="245"]/subfield[@code="a"]').text
    end
    if bib_xml.search('//record/datafield[@tag="245"]/subfield[@code="b"]').text.present?
      @title = @title + ' ' + bib_xml.search('//record/datafield[@tag="245"]/subfield[@code="b"]').text
    end
    if bib_xml.search('//record/datafield[@tag="245"]/subfield[@code="p"]').text.present?
      @title = @title + ' ' + bib_xml.search('//record/datafield[@tag="245"]/subfield[@code="p"]').text
    end

    @no_in_queue = 0

    bib_xml.search('//record/datafield[@tag="952"]').each do |item_data|
      item = Item.new(biblio_id: self.id, xml: item_data.to_xml)
      reserves_xml.search('//response/reserve').each do |reserve|
        if reserve.xpath('itemnumber').text.present?
          if reserve.xpath('itemnumber').text == item.id
            if reserve.xpath('found').text.present?
              if reserve.xpath('found').text == "T"
                item.found = "TRANSIT"
              elsif reserve.xpath('found').text == "W"
                item.found = "WAITING"
              elsif reserve.xpath('found').text == "F"
                item.found = "FINISHED"
              else
                item.found = nil
              end
            end
          end
        else
          # increase only when itemnumber is not included
          @no_in_queue += 1
        end
      end
      @items << item
    end
  end

  def self.parse_record_type leader
    code = leader[7]

    type_obj = RECORD_TYPES.find do |type|
      type[:code] == code
    end

    return "other" if type_obj.nil?

    type_obj[:label]
  end

end
