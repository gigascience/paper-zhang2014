#include "piler2.h"

enum REVSTATE
	{
	REVSTATE_Unknown = 0,
	REVSTATE_Normal = 1,
	REVSTATE_Reversed = 2
	};

struct NeighborData
	{
	int NodeIndex;
	bool Rev;
	};

typedef std::list<NeighborData> NeighborList;
typedef NeighborList::iterator PtrNeighborList;

struct NodeData
	{
	REVSTATE Rev;
	int Index;
	NeighborList *Neighbors;
	NodeData *Next;
	NodeData *Prev;
	NodeData **List;
	};

static NodeData *Nodes;

static FamData *MakeFam(NodeData *Nodes)
	{
	FamData *Fam = new FamData;
	for (const NodeData *Node = Nodes; Node; Node = Node->Next)
		{
		FamMemberData FamMember;
		FamMember.PileIndex = Node->Index;
		switch (Node->Rev)
			{
		case REVSTATE_Unknown:
			Quit("REVSTATE_Unknown");

		case REVSTATE_Normal:
			FamMember.Rev = false;
			break;

		case REVSTATE_Reversed:
			FamMember.Rev = true;
			break;
			}

		Fam->push_back(FamMember);
		}
	return Fam;
	}

static void AddNodeToList(NodeData *Node, NodeData **List)
	{
	NodeData *Head = *List;

	Node->Next = Head;
	Node->Prev = 0;

	if (Head != 0)
		Head->Prev = Node;

	Node->List = List;
	*List = Node;
	}

static void DeleteNodeFromList(NodeData *Node, NodeData **List)
	{
	assert(Node->List == List);

	NodeData *Head = *List;

	if (Node->Next != 0)
		Node->Next->Prev = Node->Prev;

	if (Node->Prev != 0)
		Node->Prev->Next = Node->Next;
	else
		*List = Node->Next;

	Node->List = 0;
	}

static NodeData *ListHead(NodeData **List)
	{
	return *List;
	}

static void MoveBetweenLists(NodeData *Node, NodeData **FromList, NodeData **ToList)
	{
	DeleteNodeFromList(Node, FromList);
	AddNodeToList(Node, ToList);
	}

static bool ListIsEmpty(NodeData **List)
	{
	return 0 == *List;
	}

static bool NodeIsInList(NodeData *Node, NodeData **List)
	{
	return Node->List == List;
	}

static void LogList(NodeData **List)
	{
	for (const NodeData *Node = *List; Node; Node = Node->Next)
		Log(" %d", Node->Index);
	Log("\n");
	}

static int GetMaxIndex(EdgeList &Edges)
	{
	int MaxIndex = -1;
	for (PtrEdgeList p = Edges.begin(); p != Edges.end(); ++p)
		{
		EdgeData &Edge = *p;
		if (Edge.Node1 > MaxIndex)
			MaxIndex = Edge.Node1;
		if (Edge.Node2 > MaxIndex)
			MaxIndex = Edge.Node2;
		}
	return MaxIndex;
	}

static REVSTATE RevState(REVSTATE Rev1, bool Rev2)
	{
	switch (Rev1)
		{
	case REVSTATE_Normal:
		if (Rev2)
			return REVSTATE_Reversed;
		return REVSTATE_Normal;

	case REVSTATE_Reversed:
		if (Rev2)
			return REVSTATE_Normal;
		return REVSTATE_Reversed;
		}
	assert(false);
	return REVSTATE_Unknown;
	}

int FindConnectedComponents(EdgeList &Edges, FamList &Fams, int MinComponentSize)
	{
	Fams.clear();

	if (0 == Edges.size())
		return 0;

	int NodeCount = GetMaxIndex(Edges) + 1;
	Nodes = new NodeData[NodeCount];

	for (int i = 0; i < NodeCount; ++i)
		{
		Nodes[i].Neighbors = new NeighborList;
		Nodes[i].Rev = REVSTATE_Unknown;
		Nodes[i].Index = i;
		}
	
	NodeData *NotVisitedList = 0;
	NodeData *PendingList = 0;
	NodeData *CurrentList = 0;

	for (PtrEdgeList p = Edges.begin(); p != Edges.end(); ++p)
		{
		EdgeData &Edge = *p;
		int From = Edge.Node1;
		int To = Edge.Node2;

		assert(From >= 0 && From < NodeCount);
		assert(To >= 0 && From < NodeCount);

		NeighborData NTo;
		NTo.NodeIndex = To;
		NTo.Rev = Edge.Rev;
		Nodes[From].Neighbors->push_back(NTo);

		NeighborData NFrom;
		NFrom.NodeIndex = From;
		NFrom.Rev = Edge.Rev;
		Nodes[To].Neighbors->push_back(NFrom);
		}

	for (int i = 0; i < NodeCount; ++i)
		AddNodeToList(&Nodes[i], &NotVisitedList);

	int FamCount = 0;
	while (!ListIsEmpty(&NotVisitedList))
		{
		int ClassSize = 0;
		NodeData *Node = ListHead(&NotVisitedList);

	// This node becomes the first in the family
	// By convention, the first member defines reversal or lack thereof.
		Node->Rev = REVSTATE_Normal;
		assert(ListIsEmpty(&PendingList));
		MoveBetweenLists(Node, &NotVisitedList, &PendingList);
		while (!ListIsEmpty(&PendingList))
			{
			Node = ListHead(&PendingList);
			assert(REVSTATE_Normal == Node->Rev || REVSTATE_Reversed == Node->Rev);
			NeighborList *Neighbors = Node->Neighbors;
			for (PtrNeighborList p = Neighbors->begin(); p != Neighbors->end(); ++p)
				{
				NeighborData &Neighbor = *p;
				int NeighborIndex = Neighbor.NodeIndex;
				NodeData *NeighborNode = &(Nodes[NeighborIndex]);
				if (NodeIsInList(NeighborNode, &NotVisitedList))
					{
					NeighborNode->Rev = RevState(Node->Rev, Neighbor.Rev);
					MoveBetweenLists(NeighborNode, &NotVisitedList, &PendingList);
					}
				}
			++ClassSize;
			MoveBetweenLists(Node, &PendingList, &CurrentList);
			}

		if (ClassSize >= MinComponentSize)
			{
			FamData *Fam = MakeFam(CurrentList);
			Fams.push_back(Fam);
			++FamCount;
			}

		CurrentList = 0;
		}
	return FamCount;
	}
