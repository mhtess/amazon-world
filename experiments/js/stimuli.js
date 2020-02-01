

var locations = ["kitchen", "bathroom", "study"]
var cost_properties = [
  {verb: "costs", amount: "$20"},
  {verb: "costs", amount: "$50"},
  {verb: "costs", amount: "$100"},
  {verb: "costs", amount: "$500"}
]

var weight_properties = [
  {verb: "weighs", amount: "5 pounds"},
  {verb: "weighs", amount: "50 pounds"},
  false
]

var simple_stimuli = []

for (loc=0;loc<locations.length; loc++) {
  for (c=0; c<cost_properties.length; c++) {
    for (w=0;w<weight_properties.length; w++) {
      // console.log(w)
      props = [ cost_properties[c] ]
      weight_properties[w] ? props.push(weight_properties[w]) : null

      simple_stimuli.push(
        {
          location: locations[loc],
          query: ["objectID"],
          properties: props,
          type: "simple"
        }
      )
    }
  }
}

// debugger;

// var conditioning_stimuli = [
//   {
//     location: "kitchen",
//     properties: [
//       {verb: "costs", amount: "$20"}
//     ],
//     query: ["objectID"]
//   },
//   {
//     location: "kitchen",
//     properties: [
//       {verb: "costs", amount: "$50"}
//     ],
//     query: ["objectID"]
//   },
//   {
//     location: "bathroom",
//     properties: [
//       {verb: "costs", amount: "$20"},
//       {verb: "weighs", amount: "5 pounds"}
//     ],
//     query: ["objectID"]
//   },
//   {
//     location: "study",
//     properties: [
//       {verb: "costs", amount: "$20"},
//       {verb: "weighs", amount: "5 pounds"}
//     ],
//     query: ["objectID"]
//   }
// ]

// var store_locations = ["same", "different"]
// var objectIDs = ["book", "table", "watch"]
// var object_counts = [1, 2, 3]
// var total_prices = ["$50", "$100", "$200"]
//
// var complex_stimuli = []
// for (i=0;i<store_locations.length; i++){
//   loc = store_locations[i]
//   for (j=0;j<unique_complex_stimuli.length; j++) {
//
//   }
// }

var complex_stimuli = [
  {
    location: "same",
    objects: [
      {
        number: 2,
        objectIDs: ["table"],
        price: "$100"
      },
      {
        number: 1,
        price: "$50",
        objectIDs: []
      }
    ],
    type: "complex",
    query: ["store", "objectID"]
  },
  {
    location: "same",
    objects: [
      {
        number: 2,
        objectIDs: ["laptop"],
        price: "$1000"
      },
      {
        number: 1,
        price: "$50",
        objectIDs: []
      }
    ],
    type: "complex",
    query: ["store", "objectID"]
  },
  {
    location: "different",
    objects: [
      {
        number: 2,
        objectIDs: ["hat"],
        price: "$100"
      },
      {
        number: 2,
        price: "$30",
        objectIDs: ["socks"]
      }
    ],
    type: "complex",
    query: ["store", "objectID"]
  },
  {
    location: "different",
    objects: [
      {
        number: 4,
        objectIDs: ["suitcase"],
        price: "$100"
      },
      {
        number: 2,
        price: "$30",
        objectIDs: ["spatula"]
      }
    ],
    type: "complex",
    query: ["store", "objectID"]
  }
]

// var single_box_stimuli = [
//   {
//     num_objects: 3,
//     contents_information: {type: ["books", 2]},
//     box_information: {price: "$20"},
//     query: "price",
//     question: "What is the price of the 3rd object?",
//     n_boxes: 1,
//   },
//   {
//     num_objects: 3,
//     contents_information: {type: ["books", 2]},
//     box_information: {price: "$50"},
//     query: "price",
//     question: "What is the price of the 3rd object?",
//     n_boxes: 1,
//   },
//   {
//     num_objects: 3,
//     contents_information: {type: ["books", 2]},
//     box_information: {price: "$20"},
//     query: "weight",
//     question: "How much does the box weigh?",
//     n_boxes: 1,
//   },
//   {
//     num_objects: 4,
//     contents_information: {type: ["books", 2]},
//     box_information: {price: "$30"},
//     query: "price",
//     question: "How much do the other two things cost in total?",
//     n_boxes: 1,
//   },
//   {
//     num_objects: 2,
//     contents_information: "Box A has a book and something else in it",
//     box_information: "Box A weighs more than Box B, which has a TV and a water bottle",
//     query: "weight",
//     question: "How much does Box A weigh?",
//     n_boxes: 2,
//   }
// ]
