class PhotosController < ApplicationController

  #Index action, photos gets listed in the order at which they were created
  def index
    @photo = Photo.order('created_at').last  # TODO  pick the right one
    @width = nil
    @height = nil
    if @photo
      geometry = Paperclip::Geometry.from_file(@photo.image)
      @width = geometry.width
      @height = geometry.height
      @bounding_boxes = image_to_bounding_boxes(@photo.image.path)
    end
  end

  #New action for creating a new photo
  def new
    @photo = Photo.new
  end

  #Create action ensures that submitted photo gets created if it meets the requirements
  def create
    @photo = Photo.new(photo_params)
    if @photo.save
      flash[:notice] = "Successfully added new photo!"
      redirect_to root_path
    else
      flash[:alert] = "Error adding new photo!"
      render :new
    end
  end

  private

  #Permitted parameters when creating a photo. This is used for security reasons.
  def photo_params
    params.require(:photo).permit(:title, :image)
  end

end

def image_to_bounding_boxes(file_name)  # TODO  better home for this
  image = RTesseract.new(file_name)
  # p image.to_box  # TODO  this is preferred but can't get it working
  tsv = image.to_tsv.read.split("\n").map { |line| line.split("\t") } #  this is why tab separated values > comma separated values
  return tsv[1..-1].map { |stick| stick[6..12] }.select { |stick| stick[-1] != '-1' }
end
