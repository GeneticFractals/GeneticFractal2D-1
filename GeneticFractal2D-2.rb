=begin
-------------------------------------------------------------------------------------
title:      GeneticFractal2D-3
author:     Henk Mulder of Genetic Fractals
date:       16 October 2014
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
$maxS=21

#canvas parameters
$canvasWidth=1000
$canvasHeight=1000
$scale=28
$xc=0
$yc=-50
#-------------------------------------------------------------------------------------
# a few constants to define the data columns in the CSV
SCol=0
AccDrCol=1
AccDrPhiLeftCol=2
AccDrPhiRightCol=3
AccBranchAngleCol=4
AccBranchCol=5
AccBranchLRCol=6
AccBranchRepeatsCol=7
AccBranchRepeatFromCol=8
AccWidthCol=9
AccColorColR=10
AccColorColG=11
AccColorColB=12
AccLuminocityCol=13

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
    
  def readAccessoryFunctions(dfile)
    accFunctions=Array.new
    #read and parse CSV file in one line. Don't you love ruby!?
    CSV.foreach(dfile,:col_sep=>"\t") do |row| accFunctions<<row end
    #delete the column headers that were read from the CSV file
    accFunctions.delete_at(0) 
    return accFunctions
  end

  def creationEquation(dR,dPhi, lastPoint, lastPhi)
    #the Creation Equation is implemented in its trigonemtric form for simplicity
    newPhi=lastPhi+dPhi #integrate over phi (it's summation really)
    return [lastPoint[0]+dR*sin(newPhi),lastPoint[1]+dR*cos(newPhi)],newPhi
  end

  def plotPoint(beginPoint,endPoint,width,color)
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
      @canvas, 
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

  def evaluate(accFunctionsOri,lastPoint,lastPhi,lastR,s,br)
    # make a deep copy of the accFunctions, i.e. a 'proper' new array with the same values. This
    # us necessary to ensure that the 'repeats' counters retain their initial values for sibling branches.
    accFunctions=Marshal.load(Marshal.dump(accFunctionsOri))
    
    # get the driver values for Dr and Dphi
    # we make dR relative to the lastR to get the right propagation of dR accross repeated sections of s.
    # This means that the Dr values in the CSV table are now relative to eachother. Just remember that :) 
    dR=accFunctions[s][1].to_f*lastR
    dPhi=accFunctions[s][br].to_f

    # check for branch point
    branchPoint=  accFunctions[s][AccBranchCol].to_i != 0 

    #first calculate the points of a branch until we hit a branch point
    while !branchPoint and s<$maxS# i.e. while it is not a branch point

      # Check for repeat point
      # If there is a such a repeat point, we decrease the repeat counter and jump
      repeats = accFunctions[s][AccBranchRepeatsCol].to_i
      if repeats != 0 then
        #reduce repeats count
        accFunctions[s][AccBranchRepeatsCol]=(repeats-1).to_s
        # jump to specified s
        s=accFunctions[s][AccBranchRepeatFromCol].to_i
      end

      #calculate next point using the Creation Equation   
      nextPoint, lastPhi = creationEquation(dR, dPhi, lastPoint.point, lastPhi)
      nextPoint=Point.new(nextPoint)

      #first we get the values of the accessory functions color, width and luminocity      
      l=accFunctions[s][AccLuminocityCol].to_f
      r=(accFunctions[s][AccColorColR].to_f*l).to_i
      g=(accFunctions[s][AccColorColG].to_f*l).to_i
      b=(accFunctions[s][AccColorColB].to_f*l).to_i
      color="#"+"%02X" % r+"%02X" % g+"%02X" % b
      width=accFunctions[s][AccWidthCol].to_f
      
      #plot it on the canvas
      plotPoint(lastPoint,nextPoint,width,color)
      
      #for the next iteration, what was the next point is now the last point
      lastPoint = nextPoint.dup
        
      #get the next driver values for Dr and Dphi and increment s
      dR=accFunctions[s][1].to_f*dR
      dPhi=accFunctions[s][br].to_f
      branchPoint=  accFunctions[s][AccBranchCol].to_i != 0 
      s+=1
    end
    
    # if we are here, 
    #    => either we have a branch point so we recursively create two branches;
    #    => or we reach the maximum value of s that we allowed and will skip this.
    if s<$maxS #check s hasn't reached the maximum
    numberBranches = accFunctions[s-1][AccBranchCol].to_i
    #bs=accFunctions[s][AccBranchCol].to_i
      for bn in 1..numberBranches
        
        # now that we allow for more than 2 branches everytime we reach a branch point, we need to \
        # 'fan out' the branches with a specified angle.  
        angle=accFunctions[s-1][AccBranchAngleCol].to_f
        
        # we also check whether the branch turns left or right, or both.
        if accFunctions[s-1][AccBranchLRCol].to_s.include? "L" then left = true else left=false end
        if accFunctions[s-1][AccBranchLRCol].to_s.include? "R" then right = true else right=false end
        
        # a bit of arithmatic to ensure that 'fan out' is centered along the current direction 
        bnf=bn.to_f-numberBranches/2.0-0.5
        
        # and here we branch recursively
        if left then evaluate(accFunctions, nextPoint, lastPhi+bnf*angle,dR, s, AccDrPhiRightCol) end # left branch
        if right then evaluate(accFunctions, nextPoint, lastPhi+bnf*angle,dR, s, AccDrPhiLeftCol) end # right branch
      end
    end
  end
  def mainPlot(accFunctions)
    root = TkRoot.new(:title => "Genetic Fractals rule!")
    @canvas = TkCanvas.new(root, :height => $canvasWidth, :width => $canvasHeight, :background => 'black')
    firstPoint=Point.new([0,0])
    firstPoint.left=[0,0]
    firstPoint.right=[0,0]
    
    # start the evaluation
    # note that accFunctions (the CSV file content) is passed into the recursive function and will be copied everytime 
    # we iterate. This allows us to have branchs repeats across sibling branches
    evaluate(accFunctions,firstPoint,3.141,1,0,AccDrPhiLeftCol)
    @canvas.pack    
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
accFunctions=niceFractal.readAccessoryFunctions("data.txt")

# create a canvas and start evaluating the fractal
niceFractal.mainPlot(accFunctions)

# done
#-------------------------------------------------------------------------------------
