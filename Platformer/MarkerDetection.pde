/* Capture Library for Webcam */
import processing.video.*;

/* NyARToolkit Processing library for Marker Detection */
import jp.nyatla.nyar4psg.*;

/* OpenCV for Perspective Correction */
import gab.opencv.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;

import org.opencv.core.Mat;
import org.opencv.core.CvType;

/* Utils */
import java.util.Arrays;

/*
    The MarkerDetection class handles all Camera Input, Perspective Correction and detection of ARToolkit Markers.
*/
class MarkerDetection{
    Capture cam;
    OpenCV opencv;
    MultiMarker nya;

    public static final int GAIN_AUTO = -1;

    private int numMarkers = 1;

    private boolean usePerspective = true;
    private ArrayList<PVector> bounds;

    public MarkerDetection(PApplet parent, int gain, int lostDelay, boolean usePerspective){
        /* Initialize Camera */
        String[] cameras = Capture.list();

        cam = new Capture(parent, cameras[0]);
        cam.start();

        /* Initialize Marker detection */
        nya = new MultiMarker(parent, width, height, "camera_zoomed.dat", NyAR4PsgConfig.CONFIG_PSG);
        nya.setLostDelay(lostDelay);
        nya.addARMarker("pattern.patt", 80);

        /* Initialize perspective Correction */
        opencv = new OpenCV(parent, 640, 480);
        bounds = this.getInitialPerspective();
        this.usePerspective = usePerspective;
    }

    /*
        Takes a Camera Frame (PImage) and tries to find one of the loaded Markers. 

        @returns: An ArrayList of the Bounding boxes (ArrayList<PVector>) of the found Markers
    */
    public ArrayList<ArrayList> detectMarkers(PImage frame){
        nya.detect(frame);

        ArrayList<ArrayList> markers = new ArrayList<ArrayList>();
        for(int i = 0; i < numMarkers; i++ ){
            if ((nya.isExistMarker(i))){
                markers.add(new ArrayList<PVector>(Arrays.asList(nya.getMarkerVertex2D(i))));
            }
        }
        
        return markers;
    }

    /*
        Gets a new Frame from the camera and applies perspective Correction.

        @returns: A Perspective-Corrected PImage.
    */
    public PImage getCorrectedFrame(){
        if (cam.available() == true) {
            cam.read();
        }
        
        PImage frame = cam; //new PImage(cam);

        /* Apply Perspective Transformation */
        if(usePerspective){
            opencv.loadImage(frame);
  
            PImage correctedFrame = createImage(width, height, ARGB);
            opencv.toPImage(warpPerspective(bounds, width, height), correctedFrame);

            frame = correctedFrame;
        }
        frame.resize(width, height);

        return frame;
    }

    /*
        Creates a Transformation Matrix for the given perspective Transformation

        @returns: An OpenCV Mat
    */
    Mat getPerspectiveTransformation(ArrayList<PVector> inputPoints, int w, int h) {
        Point[] canonicalPoints = new Point[4];
        canonicalPoints[0] = new Point(w, 0);
        canonicalPoints[1] = new Point(0, 0);
        canonicalPoints[2] = new Point(0, h);
        canonicalPoints[3] = new Point(w, h);

        MatOfPoint2f canonicalMarker = new MatOfPoint2f();
        canonicalMarker.fromArray(canonicalPoints);

        Point[] points = new Point[4];
        for (int i = 0; i < 4; i++) {
            points[i] = new Point(inputPoints.get(i).x, inputPoints.get(i).y);
        }
        
        MatOfPoint2f marker = new MatOfPoint2f(points);
        
        return Imgproc.getPerspectiveTransform(marker, canonicalMarker);
    }

    /*
        Applies a Perspective Transformation to an OpenCV image.

        @returns: An OpenCV Mat
    */
    private Mat warpPerspective(ArrayList<PVector> inputPoints, int w, int h) {
        Mat transform = getPerspectiveTransformation(inputPoints, w, h);
        Mat unWarpedMarker = new Mat(w, h, CvType.CV_8UC1);    
        Imgproc.warpPerspective(opencv.getColor(), unWarpedMarker, transform, new Size(w, h));
        return unWarpedMarker;
    }

    /*
        Returns the default Perspective bounding box (Full Camera image)

        @returns: Four Corner Points
    */
    private ArrayList<PVector> getInitialPerspective(){
        PImage camImage = cam.getFrame();

        ArrayList<PVector> bounds = new ArrayList<PVector>();

        bounds.add(new PVector(camImage.width,0)); // Top Right
        bounds.add(new PVector(0,0)); // Top Left
        bounds.add(new PVector(0,camImage.height)); // Bottom Left
        bounds.add(new PVector(camImage.width,camImage.height)); // Bottom Right

        return bounds;
    }

    /*
        Sets the Perspective bounding box for use with getCorrectedFrame()
    */
    public void setPerspective(ArrayList<PVector> bounds){
        this.bounds = bounds;
    }
}