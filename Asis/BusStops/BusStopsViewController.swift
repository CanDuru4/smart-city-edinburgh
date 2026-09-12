import UIKit
import SideMenu
import MapKit

/// Lists searchable stops and keeps a reused cell tied to the stop actually displayed.
///
/// Requests decide availability, rather than an initially unknown reachability flag.
/// Example: embed in the Stops tab and pull to refresh after an outage.
final class BusStopsViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    private let table = UITableView()
    private let refresh = UIRefreshControl()
    private let status = UIButton(type: .system)
    private let searchController = UISearchController()
    private var menu: SideMenuNavigationController?
    private var stops: [Stop] = []
    private var filteredStops: [Stop] = []
    private var selectedID: Int?
    private var loading = false
    private let geocoder = CLGeocoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        table.delegate = self
        table.dataSource = self
        table.register(BusStopTableViewCellSetup.self, forCellReuseIdentifier: BusStopTableViewCellSetup.identifer)
        table.refreshControl = refresh
        refresh.addTarget(self, action: #selector(loadStops), for: .valueChanged)
        status.titleLabel?.numberOfLines = 0
        status.titleLabel?.textAlignment = .center
        status.accessibilityIdentifier = "stopsStatus"
        status.addTarget(self, action: #selector(loadStops), for: .touchUpInside)
        table.backgroundView = status
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "searchBar")
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
        menu = SideMenuNavigationController(rootViewController: MenuListController())
        menu?.leftSide = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "sidebar.leading"), style: .plain, target: self, action: #selector(showMenu))
        loadStops()
    }

    @objc private func showMenu() {
        guard let menu else { return }
        present(menu, animated: true)
    }

    @objc private func loadStops() {
        guard !loading else { return }
        loading = true
        status.setTitle(String(localized: "loadingTransit"), for: .normal)
        let request = GetBaseData()
        request.completionHandler { [weak self] stops, success, _ in
            guard let self else { return }
            self.loading = false
            self.refresh.endRefreshing()
            self.stops = stops ?? []
            self.applyFilter()
            if !success { self.status.setTitle(String(localized: "transitUnavailableRetry"), for: .normal) }
        }
        request.getStopsBaseData(endPoint: "stops")
    }

    private func applyFilter() {
        geocoder.cancelGeocode()
        selectedID = nil
        let query = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        filteredStops = query.isEmpty ? stops : stops.filter { ($0.name ?? "").localizedCaseInsensitiveContains(query) }
        status.isHidden = !filteredStops.isEmpty
        status.setTitle(String(localized: "noStopsFound"), for: .normal)
        table.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { applyFilter() }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        applyFilter()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredStops.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BusStopTableViewCellSetup.identifer, for: indexPath) as! BusStopTableViewCellSetup
        let stop = filteredStops[indexPath.row]
        cell.busstoptableStop = stop
        cell.titleLabel.text = stop.name ?? String(localized: "unknownStop")
        cell.detailLabel_services.text = String(localized: "service") + stop.services.joined(separator: ", ")
        cell.detailLabel_destinations.text = String(localized: "destination") + stop.destinations.joined(separator: ", ")
        cell.detailLabel_adress.text = ""
        cell.imagePlace.image = UIImage(systemName: "bus")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        cell.map.removeAnnotations(cell.map.annotations)
        if let latitude = stop.latitude, let longitude = stop.longitude, stop.hasValidCoordinate {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = stop.name
            cell.map.addAnnotation(annotation)
            cell.map.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: 600, longitudinalMeters: 600), animated: false)
            if selectedID == stop.stopID {
                geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { [weak cell] placemarks, _ in
                    guard let cell, cell.busstoptableStop?.stopID == stop.stopID else { return }
                    cell.detailLabel_adress.text = String(localized: "address") + (placemarks?.first?.compactAddress ?? "")
                }
            }
        }
        cell.setSelected(selectedID == stop.stopID, animated: false)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        selectedID == filteredStops[indexPath.row].stopID ? 350 : 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        geocoder.cancelGeocode()
        let id = filteredStops[indexPath.row].stopID
        selectedID = selectedID == id ? nil : id
        tableView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        geocoder.cancelGeocode()
    }
}

extension CLPlacemark {
    var compactAddress: String? {
        if let name = name {
            var result = name

            if let street = thoroughfare {
                result += ", \(street)"
            }
            if let city = locality {
                result += ", \(city)"
            }
            if let postalCode = postalCode {
                result += ", \(postalCode)"
            }
            if let country = country {
                result += ", \(country)"
            }
            return result
        }

        return nil
    }
}
