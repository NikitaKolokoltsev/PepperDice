class Image
  include Magick

  def initialize(combination, picked = [])
    @combination = combination
    @picked = picked
  end

  def build
    top_row = ImageList.new
    bottom_row = ImageList.new(image_path('margin'))

    images_for_dices(@combination).each_with_index.map do |image, index|
      row = index < 3 ? top_row : bottom_row
      row.push(image)
    end

    image = ImageList.new
    image.push(top_row.append(false))
    image.push(bottom_row.append(false))
    image.append(true)
  end

  private

  def image_path(image)
    "#{Dir.pwd}/src/images/#{image}.png"
  end

  def images_for_dices(dices)
    dices
      .each_with_index
      .map { |dice, index| image_path(@picked.include?(index) ? "#{dice}-colorized" : dice) }
      .map { |image| Magick::Image.read(image).first }
  end
end
