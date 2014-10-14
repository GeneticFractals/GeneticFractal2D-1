=begin
-------------------------------------------------------------------------------------
title:      GeneticFractal2D-2
author:     Henk Mulder of Genetic Fractals
date:       10 October 2014
license:    Creative Commons Attribution - NonCommercial-ShareAlike 3.0 Unported license
            You may use at will non-commercially but must cite the source. Contact me in doubt
contact:    henk.mulder@geneticfractals.com

description: This ruby class generates a fractal based on the Genetic Fractal paradigm and uses the 
            Creation Equation to do so. The class reads an external file "data.txt" which contains 
            data of the driver functions dR,dPhi+,dPhi as a function of s.
             
input:      data.txt: tab separated export from excel

-------------------------------------------------------------------------------------
=end

# include / require external classes
include Math
require 'csv'
require 'tk'

#-------------------------------------------------------------------------------------
# a few global variables. No strictly necessary to be global, but it is nice to have them up here :) 

# maximimum value of s. Change this if you have more lines in the data.txt file
$maxS=99

#canvas parameters
$canvasWidth=750
$canvasHeight=750
$scale=19
$xc=0
$yc=-100
#-------------------------------------------------------------------------------------
# a few constants to define the data columns in the CSV
SCol=0
AccDrCol=1
AccDrPhiLeftCol=2
AccDrPhiRightCol=3
AccBranchCol=4
AccWidthCol=5
AccColorColR=6
AccColorColG=7
AccColorColB=8
AccLuminocityColB=9

#-------------------------------------------------------------------------------------
class Point
  attr_accessor :point, :left, :right
  def initialize(point)
    @point=point
    @left=Array.new
    @right=Array.new
  end
end

=begin
  This is the main class: GeneticFractal2D. This class has a number of useful methods
    - initialize => gets called when the class is instantiated
    - readDrivers => reads the external data.txt file with driver data
    - creationEquation => calculates the en next point of a branch with respect to the current point
    - plotPoint => this plost a line between two points on the canvas
    - evaluate => this function evaluates the points of the fractal recursively and calls "plotPoint"
    - mainPlot => sets up the canvas and triggers the "evaluate" function 
=end
class GeneticFractal2D
  #create an instance variable to keep the driver functions
  attr_accessor :drivers
  
  #create an empty array for the driver function 
  def initialize
    @AccFunctions = Array.new
  end
  
  def readAccessoryFunctions(dfile)
    #read and parse CSV file in one line. Don't you love ruby!?
    CSV.foreach(dfile,:col_sep=>"\t") do |row| @AccFunctions<<row end
    #delete the column headers that were read from the CSV file
    @AccFunctions.delete_at(0) 
  end

  def creationEquation(dR,dPhi, lastPoint, lastPhi)
    #the Creation Equation is implemented in its trigonemtric form for simplicity
    newPhi=lastPhi+dPhi #integrate over phi (it's summation really)
    return [lastPoint[0]+dR*sin(newPhi),lastPoint[1]+dR*cos(newPhi)],newPhi
  end

  def plotPoint(canvas,beginPoint,endPoint,width,color)
    # Plot the line segment between the points.
    # Instead of using a TkcLine and change its width, we draw a polygon that 
    # allows us to have a different width at the start and end of the line 
    # segment. We do this by working out the normal (perpendicukar) line segment 
    # of the normalized line segment (brought back to zero) and adding it to the
    # endPoint.
    #
    # Note that we only need to calculate the left and right points with respect
    # to the new end point since we already know the left and right points of the
    # previous point
    #
    # The coordinates are scaled and shifted to center it on the canvas
    # offset and scale are defined above
    normalizedPoint=Array.new
    normalPoint=Array.new
    normalizedPoint[0]=endPoint.point[0]-beginPoint.point[0] #bring the current vector back to the origin 
    normalizedPoint[1]=endPoint.point[1]-beginPoint.point[1] #bring the current vector back to the origin
    normalPoint[0]=-normalizedPoint[1] # find its normal (perpendicular vector)
    normalPoint[1]=normalizedPoint[0] # find its normal (perpendicular vector)
    endPoint.left[0]=endPoint.point[0]-normalPoint[0]/2*width # translate half the normal vector the end point of the new vector (left point)
    endPoint.left[1]=endPoint.point[1]-normalPoint[1]/2*width # translate half the normal vector the end point of the new vector (left point)
    endPoint.right[0]=endPoint.point[0]+normalPoint[0]/2*width # translate half the normal vector the end point of the new vector (right point)
    endPoint.right[1]=endPoint.point[1]+normalPoint[1]/2*width # translate half the normal vector the end point of the new vector (right point)
    TkcPolygon.new(
      canvas, 
      beginPoint.left[0]*$scale+$xc+$canvasWidth/2,
      beginPoint.left[1]*$scale-$yc+$canvasHeight/2,
      endPoint.left[0]*$scale+$xc+$canvasWidth/2,
      endPoint.left[1]*$scale-$yc+$canvasHeight/2,
      endPoint.right[0]*$scale+$xc+$canvasWidth/2,
      endPoint.right[1]*$scale-$yc+$canvasHeight/2,
      beginPoint.right[0]*$scale+$xc+$canvasWidth/2,
      beginPoint.right[1]*$scale-$yc+$canvasHeight/2,
      'width' => 1, 
      'fill' => color,
      'outline' => color)
  end

  def evaluate(canvas,lastPoint,lastPhi,s,br)
    #get the driver values for Dr and Dphi
    dR=@AccFunctions[s][1].to_f
    dPhi=@AccFunctions[s][br].to_f
    branchPoint=  @AccFunctions[s][AccBranchCol].to_i != 0 

    #first calculate the points of a branch until we hit a branch point
    while !branchPoint and s<$maxS# i.e. while it is not a branch point

      #calculate next point using the Creation Equation   
      nextPoint, lastPhi = creationEquation(dR, dPhi, lastPoint.point, lastPhi)
      nextPoint=Point.new(nextPoint)

      #first we get the values of the accessory functions color, width and luminocity      
      l=@AccFunctions[s][AccLuminocityColB].to_f
      r=(@AccFunctions[s][AccColorColR].to_f*l).to_i
      g=(@AccFunctions[s][AccColorColG].to_f*l).to_i
      b=(@AccFunctions[s][AccColorColB].to_f*l).to_i
      color="#"+"%02X" % r+"%02X" % g+"%02X" % b
      width=@AccFunctions[s][AccWidthCol].to_f
      
      #plot it on the canvas
      plotPoint(canvas,lastPoint,nextPoint,width,color)
      
      #for the next iteration, what was the next point is now the last point
      lastPoint = nextPoint.dup
        
      #get the next driver values for Dr and Dphi and increment s
      dR=@AccFunctions[s][1].to_f
      dPhi=@AccFunctions[s][br].to_f
      branchPoint=  @AccFunctions[s][AccBranchCol].to_i != 0 
      s+=1
    end
    
    # if we are here, 
    #    => either we have a branch point so we recursively create two branches;
    #    => or we reach the maximum value of s that we allowed and will skip this.
    if s<$maxS #check s hasn't reached the maximum
      evaluate(canvas,nextPoint, lastPhi,s,AccDrPhiRightCol) # right branch uses column 2 of the data.txt file
      evaluate(canvas,nextPoint, lastPhi,s,AccDrPhiLeftCol) # left branch uses column 3 of the data.txt file
    end
  end
  def mainPlot
    root = TkRoot.new(:title => "Genetic Fractals rule!")
    canvas = TkCanvas.new(root, :height => $canvasWidth, :width => $canvasHeight, :background => 'black')
    firstPoint=Point.new([0,0])
    firstPoint.left=[0,0]
    firstPoint.right=[0,0]
    evaluate(canvas,firstPoint,3.141,0,AccDrPhiLeftCol)
    canvas.pack    
    Tk.mainloop
  end
end
# end of GeneticFractal2D class definition 
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# the executable code below

# instantiate a fractal
niceFractal=GeneticFractal2D.new

# read the Accessory Function data
niceFractal.readAccessoryFunctions("data.txt")

# create a canvas and start evaluating the fractal
niceFractal.mainPlot

# done
#-------------------------------------------------------------------------------------
