import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    var centerCoordinate: CLLocationCoordinate2D?
    var annotations: [MapAnnotationItem]
    var showsUserLocation: Bool

    struct MapAnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let title: String
        let tint: UIColor
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        if let center = centerCoordinate {
            let region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: Constants.defaultMapSpanDelta,
                    longitudeDelta: Constants.defaultMapSpanDelta
                )
            )
            mapView.setRegion(region, animated: true)
        }

        // Update annotations
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        for item in annotations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.coordinate
            annotation.title = item.title
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(annotations: annotations)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let annotations: [MapAnnotationItem]

        init(annotations: [MapAnnotationItem]) {
            self.annotations = annotations
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
            if let matchingItem = annotations.first(where: {
                $0.coordinate.latitude == annotation.coordinate.latitude &&
                $0.coordinate.longitude == annotation.coordinate.longitude
            }) {
                view.markerTintColor = matchingItem.tint
            }
            return view
        }
    }
}
