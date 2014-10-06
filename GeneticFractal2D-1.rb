=begin
-------------------------------------------------------------------------------------
title:      GeneticFractal2D-1
author:     Henk Mulder of Genetic Fractals
date:       6 October 2014
license:    Creative Commons Attribution - NonCommercial-ShareAlike 3.0 Unported license
            You may use at will non-commercially but must cite the source. Contact me in doubt
contact:    henk.mulder@geneticfractals.com

description: This ruby class generates a fractal based on the Genetic Fractal paradigm and uses the 
            Creation Equation to do so. The class reads an external file "data.txt" which contains 
            data of the driver functions dR,dPhi+,dPhi as a function of s.
             
input:      data.txt: tab separated export from excel col0=s, col1=dR, col2=dPhi+, col3=dPhi-

-------------------------------------------------------------------------------------
=end

# include / require external classes
include Math
require 'csv'
require "tk"

#-------------------------------------------------------------------------------------
# a few global variables. No strictly necessary to be global, but it is nice to have them up here :) 

# maximimum value of s. Change this if you have more lines in the data.txt file
$maxS=50

#canvas parameters
$canvasWidth=750
$canvasHeight=750
$scale=40
$xc=0
$yc=-300

#-------------------------------------------------------------------------------------
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
    @drivers = Array.new
  end
  
  def readDrivers(dfile)
    #read and parse CSV file in one line. Don't you love ruby!?
    CSV.foreach(dfile,:col_sep=>"\t") do |row| @drivers<<row end 
  end

  def creationEquation(dR,dPhi, lastPoint, lastPhi)
    #the Creation Equation is implemented in its trigonemtric form for simplicity
    newPhi=lastPhi+dPhi #integrate over phi (it's summation really)
    return [lastPoint[0]+dR*sin(newPhi),lastPoint[1]+dR*cos(newPhi)],newPhi
  end
  
  def plotPoint(canvas,beginPoint,endPoint)
    #plot the line segment between the points. 
    #the coordinates are scaled and shifted to center it on the canvas
    #offset and scale are defined above
    TkcLine.new(
      canvas, 
      beginPoint[0]*$scale+$xc+$canvasWidth/2,
      beginPoint[1]*$scale-$yc+$canvasHeight/2,
      endPoint[0]*$scale+$xc+$canvasWidth/2,
      endPoint[1]*$scale-$yc+$canvasHeight/2,
      'width' => '1', 
      'fill' => 'black')
  end

  def evaluate(canvas,lastPoint,lastPhi,s,b)
    #get the driver values for Dr and Dphi
    dR=@drivers[s][1].to_f
    dPhi=@drivers[s][b].to_f
    
    #first calculate the points of a branch until we hit a branch point
    while dPhi!=0 and s<$maxS# i.e. while it is not a branch point
      #calculate next point using the Creation Equation   
      nextPoint, lastPhi = creationEquation(dR, dPhi, lastPoint, lastPhi)

      #plot it on the canvas
      plotPoint(canvas,lastPoint,nextPoint)
      
      #for the next iteration, what was the next point is now the last point
      lastPoint = nextPoint.dup
        
      #get the next driver values for Dr and Dphi and increment s
      dR=@drivers[s][1].to_f
      dPhi=@drivers[s][b].to_f
      s+=1
    end
    
    # if we are here, 
    #    => either we have a branch point so we recursively create two branches;
    #    => or we reach the maximum value of s that we allowed and will skip this.
    if s<$maxS #check s hasn't reached the maximum
      evaluate(canvas,nextPoint, lastPhi,s,2) # right branch uses column 2 of the data.txt file
      evaluate(canvas,nextPoint, lastPhi,s,3) # left branch uses column 3 of the data.txt file
    end
  end
  def mainPlot
    root = TkRoot.new(:title => "Genetic Fractals rule!")
    canvas = TkCanvas.new(root, :height => $canvasWidth, :width => $canvasHeight)
    evaluate(canvas,[0,0],3.141,0,2)
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

# read the driver data
niceFractal.readDrivers("data.txt")

# create a canvas and start evaluating the fractal
niceFractal.mainPlot

# done
#-------------------------------------------------------------------------------------
